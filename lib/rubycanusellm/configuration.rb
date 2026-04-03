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
      unless provider == :ollama
        raise Error, "api_key is required" if api_key.nil? || api_key.empty?
      end
      raise Error, "Unknown provider: #{provider}. Supported: #{SUPPORTED_PROVIDERS.join(", ")}" unless SUPPORTED_PROVIDERS.include?(provider)
    end

    def validate_embedding!
      effective = embedding_provider || provider
      unless EMBEDDING_PROVIDERS.include?(effective)
        raise Error, "#{provider} does not support embeddings. Set config.embedding_provider to :openai or :voyage and provide config.embedding_api_key"
      end
      if embedding_provider && (embedding_api_key.nil? || embedding_api_key.empty?)
        raise Error, "embedding_api_key is required when embedding_provider is set"
      end
    end
  end
end