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
end