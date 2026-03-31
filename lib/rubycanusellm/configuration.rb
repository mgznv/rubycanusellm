# frozen_string_literal: true

module RubyCanUseLLM
  class Configuration
    SUPPORTED_PROVIDERS = %i[openai anthropic].freeze

    attr_accessor :provider, :api_key, :model, :timeout

    def initialize
      @provider = nil
      @api_key = nil
      @model = nil
      @timeout = 30
    end

    def validate!
      raise Error, "provider is required. Use :openai or :anthropic" if provider.nil?
      raise Error, "api_key is required" if api_key.nil? || api_key.empty?
      raise Error, "Unknown provider: #{provider}. Supported: #{SUPPORTED_PROVIDERS.join(", ")}" unless SUPPORTED_PROVIDERS.include?(provider)
    end
  end
end