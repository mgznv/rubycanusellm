# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::Providers::Ollama do
  let(:config) do
    RubyCanUseLLM::Configuration.new.tap do |c|
      c.provider = :ollama
    end
  end

  let(:provider) { described_class.new(config) }

  let(:success_body) do
    {
      message: { role: "assistant", content: "Hello!" },
      model: "llama3.2",
      done: true,
      prompt_eval_count: 10,
      eval_count: 5
    }.to_json
  end

  describe "#chat" do
    it "returns a unified Response" do
      stub_request(:post, "http://localhost:11434/api/chat")
        .to_return(status: 200, body: success_body)

      response = provider.chat([{ role: :user, content: "Hi" }])

      expect(response).to be_a(RubyCanUseLLM::Response)
      expect(response.content).to eq("Hello!")
      expect(response.model).to eq("llama3.2")
      expect(response.input_tokens).to eq(10)
      expect(response.output_tokens).to eq(5)
      expect(response.total_tokens).to eq(15)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "http://localhost:11434/api/chat")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end

    context "with stream: true" do
      let(:stream_body) do
        [
          { model: "llama3.2", message: { role: "assistant", content: "Hello" }, done: false }.to_json,
          { model: "llama3.2", message: { role: "assistant", content: "!" }, done: false }.to_json,
          { model: "llama3.2", message: { role: "assistant", content: "" }, done: true, prompt_eval_count: 10,
            eval_count: 5 }.to_json
        ].join("\n")
      end

      it "yields Chunks with content" do
        stub_request(:post, "http://localhost:11434/api/chat")
          .to_return(status: 200, body: stream_body)

        chunks = []
        provider.chat([{ role: :user, content: "Hi" }], stream: true) do |chunk|
          chunks << chunk
        end

        expect(chunks.size).to eq(2)
        expect(chunks).to all(be_a(RubyCanUseLLM::Chunk))
        expect(chunks.map(&:content)).to eq(["Hello", "!"])
      end

      it "raises ProviderError on non-200" do
        stub_request(:post, "http://localhost:11434/api/chat")
          .to_return(status: 500, body: "error")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_c| } }
          .to raise_error(RubyCanUseLLM::ProviderError)
      end
    end

    context "with custom base_url" do
      let(:config) do
        RubyCanUseLLM::Configuration.new.tap do |c|
          c.provider = :ollama
          c.base_url = "http://myserver:11434"
        end
      end

      it "uses the custom base_url" do
        stub_request(:post, "http://myserver:11434/api/chat")
          .to_return(status: 200, body: success_body)

        response = provider.chat([{ role: :user, content: "Hi" }])
        expect(response.content).to eq("Hello!")
      end
    end
  end

  describe "#chat with tools" do
    let(:tool_call_body) do
      {
        message: {
          role: "assistant",
          content: "",
          tool_calls: [{ function: { name: "get_time", arguments: { "timezone" => "UTC" } } }]
        },
        model: "llama3.2",
        done: true,
        prompt_eval_count: 10,
        eval_count: 5
      }.to_json
    end

    let(:tools) do
      [{
        name: "get_time",
        description: "Get current time",
        parameters: { type: "object", properties: { timezone: { type: "string" } }, required: ["timezone"] }
      }]
    end

    it "returns a Response with tool_calls" do
      stub_request(:post, "http://localhost:11434/api/chat")
        .to_return(status: 200, body: tool_call_body)

      response = provider.chat([{ role: :user, content: "What time is it?" }], tools: tools)

      expect(response.tool_call?).to be true
      tc = response.tool_calls.first
      expect(tc.id).to eq("call_0")
      expect(tc.name).to eq("get_time")
      expect(tc.arguments).to eq({ "timezone" => "UTC" })
    end
  end

  describe "#embed" do
    let(:embedding_body) do
      {
        embeddings: [[0.1, 0.2, 0.3]],
        model: "nomic-embed-text",
        prompt_eval_count: 3
      }.to_json
    end

    it "returns an EmbeddingResponse" do
      stub_request(:post, "http://localhost:11434/api/embed")
        .to_return(status: 200, body: embedding_body)

      response = provider.embed("Hello world")

      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.embedding).to eq([0.1, 0.2, 0.3])
      expect(response.model).to eq("nomic-embed-text")
      expect(response.tokens).to eq(3)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "http://localhost:11434/api/embed")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end
  end
end
