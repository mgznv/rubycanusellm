# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::Providers::Mistral do
  let(:config) do
    RubyCanUseLLM::Configuration.new.tap do |c|
      c.provider = :mistral
      c.api_key = "test-mistral-key"
    end
  end

  let(:provider) { described_class.new(config) }

  let(:success_body) do
    {
      choices: [{ message: { role: "assistant", content: "Bonjour!" } }],
      model: "mistral-small-latest",
      usage: { prompt_tokens: 8, completion_tokens: 4 }
    }.to_json
  end

  describe "#chat" do
    it "returns a unified Response" do
      stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
        .to_return(status: 200, body: success_body)

      response = provider.chat([{ role: :user, content: "Hi" }])

      expect(response).to be_a(RubyCanUseLLM::Response)
      expect(response.content).to eq("Bonjour!")
      expect(response.model).to eq("mistral-small-latest")
      expect(response.input_tokens).to eq(8)
      expect(response.output_tokens).to eq(4)
      expect(response.total_tokens).to eq(12)
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
        .to_return(status: 401, body: "Unauthorized")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
        .to_return(status: 429, body: "Too Many Requests")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::RateLimitError)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end

    context "with stream: true" do
      let(:sse_body) do
        [
          %(data: {"id":"cmpl-1","choices":[{"delta":{"role":"assistant","content":""},"index":0}]}),
          %(data: {"id":"cmpl-1","choices":[{"delta":{"content":"Bonjour"},"index":0}]}),
          %(data: {"id":"cmpl-1","choices":[{"delta":{"content":"!"},"index":0}]}),
          "data: [DONE]",
          ""
        ].join("\n")
      end

      it "yields Chunks with content" do
        stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
          .to_return(status: 200, body: sse_body)

        chunks = []
        provider.chat([{ role: :user, content: "Hi" }], stream: true) do |chunk|
          chunks << chunk
        end

        expect(chunks.size).to eq(2)
        expect(chunks).to all(be_a(RubyCanUseLLM::Chunk))
        expect(chunks.map(&:content)).to eq(["Bonjour", "!"])
      end

      it "raises AuthenticationError on 401" do
        stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
          .to_return(status: 401, body: "Unauthorized")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_c| } }
          .to raise_error(RubyCanUseLLM::AuthenticationError)
      end

      it "raises RateLimitError on 429" do
        stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
          .to_return(status: 429, body: "Too Many Requests")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_c| } }
          .to raise_error(RubyCanUseLLM::RateLimitError)
      end
    end
  end

  describe "#chat with tools" do
    let(:tool_call_body) do
      {
        choices: [{
          message: {
            role: "assistant",
            content: nil,
            tool_calls: [{
              id: "call_xyz",
              type: "function",
              function: { name: "translate", arguments: '{"text":"hello","target":"fr"}' }
            }]
          }
        }],
        model: "mistral-small-latest",
        usage: { prompt_tokens: 15, completion_tokens: 8 }
      }.to_json
    end

    let(:tools) do
      [{
        name: "translate",
        description: "Translate text",
        parameters: { type: "object", properties: { text: { type: "string" }, target: { type: "string" } }, required: ["text", "target"] }
      }]
    end

    it "returns a Response with tool_calls" do
      stub_request(:post, "https://api.mistral.ai/v1/chat/completions")
        .to_return(status: 200, body: tool_call_body)

      response = provider.chat([{ role: :user, content: "Translate hello to French" }], tools: tools)

      expect(response.tool_call?).to be true
      tc = response.tool_calls.first
      expect(tc.id).to eq("call_xyz")
      expect(tc.name).to eq("translate")
      expect(tc.arguments).to eq({ "text" => "hello", "target" => "fr" })
    end
  end

  describe "#embed" do
    let(:embedding_body) do
      {
        data: [{ embedding: [0.1, 0.2, 0.3] }],
        model: "mistral-embed",
        usage: { total_tokens: 6 }
      }.to_json
    end

    it "returns an EmbeddingResponse" do
      stub_request(:post, "https://api.mistral.ai/v1/embeddings")
        .to_return(status: 200, body: embedding_body)

      response = provider.embed("Hello world")

      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.embedding).to eq([0.1, 0.2, 0.3])
      expect(response.model).to eq("mistral-embed")
      expect(response.tokens).to eq(6)
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.mistral.ai/v1/embeddings")
        .to_return(status: 401, body: "Unauthorized")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:post, "https://api.mistral.ai/v1/embeddings")
        .to_return(status: 429, body: "Too Many Requests")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::RateLimitError)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "https://api.mistral.ai/v1/embeddings")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end
  end
end
