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
  end
end