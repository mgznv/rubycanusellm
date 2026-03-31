# frozen_string_literal: true

require_relative "rubycanusellm/version"
require_relative "rubycanusellm/configuration"

module RubyCanUseLLM
  class Error < StandardError; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset!
      @configuration = Configuration.new
    end
  end
end