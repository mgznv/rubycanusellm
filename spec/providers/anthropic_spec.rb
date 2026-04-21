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

    context "with tools" do
      let(:tool_call_body) do
        {
          content: [
            { type: "text", text: "I'll check the weather." },
            { type: "tool_use", id: "toolu_abc", name: "get_weather", input: { "location" => "Paris" } }
          ],
          model: "claude-sonnet-4-20250514",
          usage: { input_tokens: 25, output_tokens: 15 }
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
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(status: 200, body: tool_call_body)

        response = provider.chat([{ role: :user, content: "Weather in Paris?" }], tools: tools)

        expect(response.tool_call?).to be true
        expect(response.content).to eq("I'll check the weather.")
        tc = response.tool_calls.first
        expect(tc.id).to eq("toolu_abc")
        expect(tc.name).to eq("get_weather")
        expect(tc.arguments).to eq({ "location" => "Paris" })
      end

      it "sends tools in Anthropic format (input_schema, not parameters)" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .with { |req| JSON.parse(req.body)["tools"].first.key?("input_schema") }
          .to_return(status: 200, body: tool_call_body)

        provider.chat([{ role: :user, content: "Weather?" }], tools: tools)
      end

      it "formats tool result messages as user messages with tool_result content" do
        tc = RubyCanUseLLM::ToolCall.new(id: "toolu_abc", name: "get_weather", arguments: { "location" => "Paris" })
        messages = [
          { role: :user, content: "Weather in Paris?" },
          { role: :assistant, content: "I'll check.", tool_calls: [tc] },
          { role: :tool, tool_call_id: "toolu_abc", name: "get_weather", content: "Sunny, 25°C" }
        ]

        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .with do |req|
            body = JSON.parse(req.body)
            last = body["messages"].last
            last["role"] == "user" &&
              last["content"].first["type"] == "tool_result" &&
              last["content"].first["tool_use_id"] == "toolu_abc"
          end
          .to_return(status: 200, body: success_body)

        response = provider.chat(messages, tools: tools)
        expect(response.content).to eq("Hello!")
      end
    end

    context "with response_format: :json" do
      let(:json_body) do
        {
          content: [{ type: "text", text: '{"city":"Paris","pop":2161000}' }],
          model: "claude-sonnet-4-20250514",
          usage: { input_tokens: 15, output_tokens: 10 }
        }.to_json
      end

      it "injects JSON instruction into system prompt" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .with { |req| JSON.parse(req.body)["system"].include?("valid JSON") }
          .to_return(status: 200, body: json_body)

        provider.chat([{ role: :user, content: "Return JSON" }], response_format: :json)
      end

      it "preserves an existing system prompt when injecting JSON instruction" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .with do |req|
            system = JSON.parse(req.body)["system"]
            system.include?("You are helpful") && system.include?("valid JSON")
          end
          .to_return(status: 200, body: json_body)

        messages = [
          { role: :system, content: "You are helpful" },
          { role: :user, content: "Return JSON" }
        ]
        provider.chat(messages, response_format: :json)
      end

      it "response.parsed returns a Hash" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(status: 200, body: json_body)

        response = provider.chat([{ role: :user, content: "Return JSON" }], response_format: :json)
        expect(response.parsed).to eq({ "city" => "Paris", "pop" => 2_161_000 })
      end
    end

    context "with stream: true" do
      let(:sse_body) do
        [
          "event: message_start",
          %(data: {"type":"message_start","message":{"id":"msg_1","type":"message","role":"assistant","model":"claude-sonnet-4-20250514","usage":{"input_tokens":12,"output_tokens":0}}}),
          "",
          "event: content_block_start",
          %(data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}),
          "",
          "event: content_block_delta",
          %(data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"Hello"}}),
          "",
          "event: content_block_delta",
          %(data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"!"}}),
          "",
          "event: content_block_stop",
          %(data: {"type":"content_block_stop","index":0}),
          "",
          "event: message_stop",
          %(data: {"type":"message_stop"}),
          ""
        ].join("\n")
      end

      it "yields Chunks with content" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
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
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .with { |req| JSON.parse(req.body)["stream"] == true }
          .to_return(status: 200, body: sse_body)

        provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_chunk| }
      end

      it "raises AuthenticationError on 401" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(status: 401, body: "Unauthorized")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_chunk| } }
          .to raise_error(RubyCanUseLLM::AuthenticationError)
      end

      it "raises RateLimitError on 429" do
        stub_request(:post, "https://api.anthropic.com/v1/messages")
          .to_return(status: 429, body: "Too Many Requests")

        expect { provider.chat([{ role: :user, content: "Hi" }], stream: true) { |_chunk| } }
          .to raise_error(RubyCanUseLLM::RateLimitError)
      end
    end
  end
end
