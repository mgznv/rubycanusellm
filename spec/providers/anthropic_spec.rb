# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::Providers::Anthropic do
  let(:config) do
    RubyCanUseLLM::Configuration.new.tap do |c|
      c.provider = :anthropic
      c.api_key = "test-key"
      c.model = "claude-sonnet-4-20250514"
    end
  end

  let(:provider) { described_class.new(config) }

  let(:success_body) do
    {
      content: [{ type: "text", text: "Hello!" }],
      model: "claude-sonnet-4-20250514",
      usage: { input_tokens: 12, output_tokens: 8 }
    }.to_json
  end

  describe "#chat" do
    it "returns a unified Response" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 200, body: success_body)

      response = provider.chat([{ role: :user, content: "Hi" }])

      expect(response).to be_a(RubyCanUseLLM::Response)
      expect(response.content).to eq("Hello!")
      expect(response.model).to eq("claude-sonnet-4-20250514")
      expect(response.input_tokens).to eq(12)
      expect(response.output_tokens).to eq(8)
      expect(response.total_tokens).to eq(20)
    end

    it "extracts system message from messages array" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .with { |req| JSON.parse(req.body)["system"] == "You are helpful" }
        .to_return(status: 200, body: success_body)

      messages = [
        { role: :system, content: "You are helpful" },
        { role: :user, content: "Hi" }
      ]

      response = provider.chat(messages)
      expect(response.content).to eq("Hello!")
    end

    it "raises AuthenticationError on 401" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 401, body: "Unauthorized")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::AuthenticationError)
    end

    it "raises RateLimitError on 429" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 429, body: "Too Many Requests")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::RateLimitError)
    end

    it "raises ProviderError on 500" do
      stub_request(:post, "https://api.anthropic.com/v1/messages")
        .to_return(status: 500, body: "Internal Server Error")

      expect { provider.chat([{ role: :user, content: "Hi" }]) }
        .to raise_error(RubyCanUseLLM::ProviderError)
    end
  end
end