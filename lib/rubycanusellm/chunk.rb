# frozen_string_literal: true

module RubyCanUseLLM
  class Chunk
    attr_reader :content, :role

    def initialize(content:, role: "assistant")
      @content = content
      @role = role
    end
  end
end
