# frozen_string_literal: true

module RubyCanUseLLM
  class Response
    attr_reader :content, :model, :input_tokens, :output_tokens, :raw

    def initialize(content:, model:, input_tokens:, output_tokens:, raw:)
      @content = content
      @model = model
      @input_tokens = input_tokens
      @output_tokens = output_tokens
      @raw = raw
    end

    def total_tokens
      input_tokens + output_tokens
    end
  end
end