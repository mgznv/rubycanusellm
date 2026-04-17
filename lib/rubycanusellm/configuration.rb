# frozen_string_literal: true

module RubyCanUseLLM
  class Configuration
    SUPPORTED_PROVIDERS = %i[openai anthropic voyage mistral ollama].freeze
    EMBEDDING_PROVIDERS = %i[openai voyage mistral ollama].freeze

    attr_accessor :provider, :api_key, :model, :timeout, :embedding_provider, :embedding_api_key, :base_url

    def initialize
      @provider = nil
      @api_key = nil
      @model = nil
      @timeout = 30
      @embedding_provider = nil
      @embedding_api_key = nil
      @base_url = nil
    end

    def validate!
      raise Error, "provider is required. Use :openai, :anthropic, :mistral, or :ollama" if provider.nil?

      raise Error, "api_key is required" if provider != :ollama && (api_key.nil? || api_key.empty?)
      return if SUPPORTED_PROVIDERS.include?(provider)

      raise Error,
            "Unknown provider: #{provider}. Supported: #{SUPPORTED_PROVIDERS.join(", ")}"
    end

    def validate_embedding!
      effective = embedding_provider || provider
      unless EMBEDDING_PROVIDERS.include?(effective)
        raise Error,
              "#{provider} does not support embeddings. Set config.embedding_provider to :openai or :voyage and provide config.embedding_api_key"
      end
      return unless embedding_provider && (embedding_api_key.nil? || embedding_api_key.empty?)

      raise Error, "embedding_api_key is required when embedding_provider is set"
    end
  end
end
