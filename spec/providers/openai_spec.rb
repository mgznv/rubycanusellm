# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::Providers::OpenAI do
  let(:config) do
    RubyCanUseLLM::Configuration.new.tap do |c|
      c.provider = :openai
      c.api_key = "test-key"
      c.model = "gpt-4o-mini"
    end
  end

  let(:provider) { described_class.new(config) }

  let(:success_body) do
    {
      choices: [{ message: { role: "assistant", content: "Hello!" } }],
      model: "gpt-4o-mini",
      usage: { prompt_tokens: 10, completion_tokens: 5 }
    }.to_json
  end

  describe "#chat" do
    it "returns a unified Response" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 200, body: success_body)

      response = provider.chat([{ role: :user, content: "Hi" }])

      expect(response).to be_a(RubyCanUseLLM::Response)
      expect(response.content).to eq("Hello!")
      expect(response.model).to eq("gpt-4o-mini")
      expect(response.input_tokens).to eq(10)
      expect(response.output_tokens).to eq(5)
      expect(response.total_tokens).to eq(15)
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 401, body: "Unauthorized")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 429, body: "Too Many Requests")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::RateLimitError)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end

    context "with stream: true" do
      let(:sse_body) do
        [
          %(data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"delta":{"role":"assistant","content":""},"index":0}]}),
          %(data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"delta":{"content":"Hello"},"index":0}]}),
          %(data: {"id":"chatcmpl-1","object":"chat.completion.chunk","choices":[{"delta":{"content":"!"},"index":0}]}),
          "data: [DONE]",
          ""
        ].join("\n")
      end

      it "yields Chunks with content" do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(status: 200, body: sse_body)

        chunks = []
        provider.chat([{ role: :user, content: "Hi" }], stream: true) do |chunk|
          chunks << chunk
        end

        expect(chunks.size).to eq(2)
        expect(chunks).to all(be_a(RubyCanUseLLM::Chunk))
        expect(chunks.map(&:content)).to eq(["Hello", "!"])
        expect(chunks.map(&:role)).to all(eq("assistant"))
      end

      it "sends stream: true in request body" do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .with { |req| JSON.parse(req.body)["stream"] == true }
          .to_return(status: 200, body: sse_body)

        provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_chunk| }
      end

      it "raises AuthenticationError on 401" do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(status: 401, body: "Unauthorized")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_chunk| } }
          .to raise_error(RubyCanUseLLM::AuthenticationError)
      end

      it "raises RateLimitError on 429" do
        stub_request(:post, "https://api.openai.com/v1/chat/completions")
          .to_return(status: 429, body: "Too Many Requests")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_chunk| } }
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
              id: "call_abc123",
              type: "function",
              function: { name: "get_weather", arguments: '{"location":"Paris"}' }
            }]
          }
        }],
        model: "gpt-4o-mini",
        usage: { prompt_tokens: 20, completion_tokens: 10 }
      }.to_json
    end

    let(:tools) do
      [{
        name: "get_weather",
        description: "Get weather for a city",
        parameters: { type: "object", properties: { location: { type: "string" } }, required: ["location"] }
      }]
    end

    it "returns a Response with tool_calls" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 200, body: tool_call_body)

      response = provider.chat([{ role: :user, content: "Weather in Paris?" }], tools: tools)

      expect(response.tool_call?).to be true
      expect(response.tool_calls.size).to eq(1)
      tc = response.tool_calls.first
      expect(tc).to be_a(RubyCanUseLLM::ToolCall)
      expect(tc.id).to eq("call_abc123")
      expect(tc.name).to eq("get_weather")
      expect(tc.arguments).to eq({ "location" => "Paris" })
    end

    it "sends tools in the request body" do
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with { |req| JSON.parse(req.body)["tools"].first["type"] == "function" }
        .to_return(status: 200, body: tool_call_body)

      provider.chat([{ role: :user, content: "Weather?" }], tools: tools)
    end

    it "formats tool result messages correctly" do
      tc = RubyCanUseLLM::ToolCall.new(id: "call_abc123", name: "get_weather", arguments: { "location" => "Paris" })
      messages = [
        { role: :user, content: "Weather in Paris?" },
        { role: :assistant, content: nil, tool_calls: [tc] },
        { role: :tool, tool_call_id: "call_abc123", name: "get_weather", content: "Sunny, 25°C" }
      ]

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .with { |req|
          body = JSON.parse(req.body)
          body["messages"].last["role"] == "tool" &&
            body["messages"].last["tool_call_id"] == "call_abc123"
        }
        .to_return(status: 200, body: success_body)

      response = provider.chat(messages, tools: tools)
      expect(response.content).to eq("Hello!")
    end
  end

  describe "#embed" do
    let(:embedding_body) do
      {
        data: [{ embedding: [0.1, 0.2, 0.3] }],
        model: "text-embedding-3-small",
        usage: { total_tokens: 5 }
      }.to_json
    end

    it "returns an EmbeddingResponse" do
      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(status: 200, body: embedding_body)

      response = provider.embed("Hello world")

      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.embedding).to eq([0.1, 0.2, 0.3])
      expect(response.model).to eq("text-embedding-3-small")
      expect(response.tokens).to eq(5)
    end
  end
end
