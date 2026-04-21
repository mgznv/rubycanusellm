# frozen_string_literal: true

module RubyCanUseLLM
  class Response
    attr_reader :content, :model, :input_tokens, :output_tokens, :tool_calls, :raw

    def initialize(content:, model:, input_tokens:, output_tokens:, raw:, tool_calls: nil)
      @content = content
      @model = model
      @input_tokens = input_tokens
      @output_tokens = output_tokens
      @tool_calls = tool_calls
      @raw = raw
    end

    def tool_call?
      !tool_calls.nil? && !tool_calls.empty?
    end

    def parsed
      JSON.parse(content)
    end

    def total_tokens
      input_tokens + output_tokens
    end
  end
end
