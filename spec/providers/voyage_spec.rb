# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::Providers::Voyage do
  let(:config) do
    RubyCanUseLLM::Configuration.new.tap do |c|
      c.provider = :voyage
      c.api_key = "test-voyage-key"
    end
  end

  let(:provider) { described_class.new(config) }

  let(:embedding_body) do
    {
      data: [{ embedding: [0.1, 0.2, 0.3] }],
      model: "voyage-3.5",
      usage: { total_tokens: 4 }
    }.to_json
  end

  describe "#embed" do
    it "returns an EmbeddingResponse with correct data" do
      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .to_return(status: 200, body: embedding_body)

      response = provider.embed("Hello world")

      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.embedding).to eq([0.1, 0.2, 0.3])
      expect(response.model).to eq("voyage-3.5")
      expect(response.tokens).to eq(4)
    end

    it "uses voyage-3.5 as default model" do
      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .with { |req| JSON.parse(req.body)["model"] == "voyage-3.5" }
        .to_return(status: 200, body: embedding_body)

      provider.embed("Hello world")
    end

    it "accepts a custom model" do
      custom_body = { data: [{ embedding: [0.4, 0.5] }], model: "voyage-4", usage: { total_tokens: 3 } }.to_json

      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .with { |req| JSON.parse(req.body)["model"] == "voyage-4" }
        .to_return(status: 200, body: custom_body)

      response = provider.embed("Hello", model: "voyage-4")
      expect(response.model).to eq("voyage-4")
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .to_return(status: 401, body: "Unauthorized")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .to_return(status: 429, body: "Too Many Requests")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::RateLimitError)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.embed("Hello") }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end
  end

  describe "#chat" do
    it "raises an error indicating Voyage only supports embeddings" do
      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::Error, "Voyage AI only supports embeddings, not chat completions")
    end
  end
end
