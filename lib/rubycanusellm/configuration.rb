# frozen_string_literal: true

module RubyCanUseLLM
  class Configuration
    attr_accessor :provider, :api_key, :model, :timeout

    def initialize
      @provider = nil
      @api_key = nil
      @model = nil
      @timeout = 30
    end
  end
end