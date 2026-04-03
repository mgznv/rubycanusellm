# frozen_string_literal: true

require_relative "rubycanusellm/version"
require_relative "rubycanusellm/configuration"
require_relative "rubycanusellm/errors"
require_relative "rubycanusellm/response"
require_relative "rubycanusellm/chunk"
require_relative "rubycanusellm/providers/base"
require_relative "rubycanusellm/providers/openai"
require_relative "rubycanusellm/providers/anthropic"
require_relative "rubycanusellm/embedding_response"

module RubyCanUseLLM
  PROVIDERS = {
    openai: Providers::OpenAI,
    anthropic: Providers::Anthropic
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
    end

    def client
      configuration.validate!
      @client ||= PROVIDERS.fetch(configuration.provider) do
        raise Error, "Unknown provider: #{configuration.provider}"
      end.new(configuration)
    end

    def chat(messages, **options, &block)
      client.chat(messages, **options, &block)
    end

    def embed(text, **options)
      client.embed(text, **options)
    end
  end
end