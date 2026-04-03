# frozen_string_literal: true

require_relative "rubycanusellm/version"
require_relative "rubycanusellm/configuration"
require_relative "rubycanusellm/errors"
require_relative "rubycanusellm/response"
require_relative "rubycanusellm/chunk"
require_relative "rubycanusellm/providers/base"
require_relative "rubycanusellm/providers/openai"
require_relative "rubycanusellm/providers/anthropic"
require_relative "rubycanusellm/providers/voyage"
require_relative "rubycanusellm/embedding_response"

module RubyCanUseLLM
  PROVIDERS = {
    openai: Providers::OpenAI,
    anthropic: Providers::Anthropic,
    voyage: Providers::Voyage
  }.freeze

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset!
      @configuration = Configuration.new
      @client = nil
      @embedding_client = nil
    end

    def client
      configuration.validate!
      @client ||= PROVIDERS.fetch(configuration.provider) do
        raise Error, "Unknown provider: #{configuration.provider}"
      end.new(configuration)
    end

    def embedding_client
      configuration.validate_embedding!
      if configuration.embedding_provider
        @embedding_client ||= begin
          cfg = Configuration.new
          cfg.provider = configuration.embedding_provider
          cfg.api_key = configuration.embedding_api_key
          cfg.timeout = configuration.timeout
          PROVIDERS[configuration.embedding_provider].new(cfg)
        end
      else
        client
      end
    end

    def chat(messages, **options, &block)
      client.chat(messages, **options, &block)
    end

    def embed(text, **options)
      embedding_client.embed(text, **options)
    end
  end
end