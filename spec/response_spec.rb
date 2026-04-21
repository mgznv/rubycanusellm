# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::Response do
  let(:response) do
    described_class.new(
      content: '{"name":"Juan","score":42}',
      model: "gpt-4o-mini",
      input_tokens: 5,
      output_tokens: 10,
      raw: {}
    )
  end

  describe "#parsed" do
    it "parses JSON content into a Hash" do
      expect(response.parsed).to eq({ "name" => "Juan", "score" => 42 })
    end

    it "raises JSON::ParserError when content is not valid JSON" do
      bad = described_class.new(content: "plain text", model: "x", input_tokens: 0, output_tokens: 0, raw: {})
      expect { bad.parsed }.to raise_error(JSON::ParserError)
    end
  end
end
