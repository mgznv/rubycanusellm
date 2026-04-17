# frozen_string_literal: true

module RubyCanUseLLM
  class Error < StandardError; end
  class AuthenticationError < Error; end
  class RateLimitError < Error; end
  class TimeoutError < Error; end
  class ProviderError < Error; end
end
