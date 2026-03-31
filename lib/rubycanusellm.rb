# frozen_string_literal: true

require_relative "rubycanusellm/version"
require_relative "rubycanusellm/configuration"
require_relative "rubycanusellm/errors"
module RubyCanUseLLM
  
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