# frozen_string_literal: true

RSpec.describe RubyCanUseLLM do
  after { described_class.reset! }

  describe ".configure" do
    it "sets provider and api_key" do
      described_class.configure do |config|
        config.provider = :openai
        config.api_key = "test-key"
        config.model = "gpt-4"
      end

      expect(described_class.configuration.provider).to eq(:openai)
      expect(described_class.configuration.api_key).to eq("test-key")
      expect(described_class.configuration.model).to eq("gpt-4")
    end

    it "has a default timeout of 30" do
      expect(described_class.configuration.timeout).to eq(30)
    end
  end

  describe ".reset!" do
    it "restores default configuration" do
      described_class.configure do |config|
        config.provider = :anthropic
      end

      described_class.reset!

      expect(described_class.configuration.provider).to be_nil
    end
  end

  describe "Configuration#validate!" do
    it "raises error when provider is nil" do
      expect { described_class.configuration.validate! }
        .to raise_error(RubyCanUseLLM::Error, /provider is required/)
    end

    it "raises error when api_key is nil" do
      described_class.configure { |c| c.provider = :openai }

      expect { described_class.configuration.validate! }
        .to raise_error(RubyCanUseLLM::Error, /api_key is required/)
    end

    it "raises error for unsupported provider" do
      described_class.configure do |c|
        c.provider = :unknown
        c.api_key = "test-key"
      end

      expect { described_class.configuration.validate! }
        .to raise_error(RubyCanUseLLM::Error, /Unknown provider/)
    end

    it "passes with valid configuration" do
      described_class.configure do |c|
        c.provider = :openai
        c.api_key = "test-key"
      end

      expect { described_class.configuration.validate! }.not_to raise_error
    end
  end

  describe ".embed via embedding_client" do
    let(:openai_embedding_body) do
      { data: [{ embedding: [0.1, 0.2, 0.3] }], model: "text-embedding-3-small", usage: { total_tokens: 5 } }.to_json
    end

    let(:voyage_embedding_body) do
      { data: [{ embedding: [0.4, 0.5, 0.6] }], model: "voyage-3.5", usage: { total_tokens: 4 } }.to_json
    end

    it "OpenAI provider without embedding_provider uses OpenAI for embed" do
      described_class.configure do |c|
        c.provider = :openai
        c.api_key = "openai-key"
      end

      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(status: 200, body: openai_embedding_body)

      response = described_class.embed("hello")
      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.model).to eq("text-embedding-3-small")
    end

    it "Anthropic provider with embedding_provider: :voyage uses Voyage AI" do
      described_class.configure do |c|
        c.provider = :anthropic
        c.api_key = "anthropic-key"
        c.embedding_provider = :voyage
        c.embedding_api_key = "voyage-key"
      end

      stub_request(:post, "https://api.voyageai.com/v1/embeddings")
        .to_return(status: 200, body: voyage_embedding_body)

      response = described_class.embed("hello")
      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.model).to eq("voyage-3.5")
    end

    it "Anthropic provider with embedding_provider: :openai uses OpenAI" do
      described_class.configure do |c|
        c.provider = :anthropic
        c.api_key = "anthropic-key"
        c.embedding_provider = :openai
        c.embedding_api_key = "openai-key"
      end

      stub_request(:post, "https://api.openai.com/v1/embeddings")
        .to_return(status: 200, body: openai_embedding_body)

      response = described_class.embed("hello")
      expect(response).to be_a(RubyCanUseLLM::EmbeddingResponse)
      expect(response.model).to eq("text-embedding-3-small")
    end

    it "Anthropic provider without embedding_provider raises a clear error" do
      described_class.configure do |c|
        c.provider = :anthropic
        c.api_key = "anthropic-key"
      end

      expect { described_class.embed("hello") }
        .to raise_error(RubyCanUseLLM::Error, /anthropic does not support embeddings/)
    end

    it "embedding_provider set without embedding_api_key raises a clear error" do
      described_class.configure do |c|
        c.provider = :anthropic
        c.api_key = "anthropic-key"
        c.embedding_provider = :voyage
      end

      expect { described_class.embed("hello") }
        .to raise_error(RubyCanUseLLM::Error, /embedding_api_key is required/)
    end
  end
end
