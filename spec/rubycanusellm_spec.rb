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
end