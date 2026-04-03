# frozen_string_literal: true

module RubyCanUseLLM
  module Providers
    class Base
      def initialize(config)
        @config = config
      end

      def chat(messages, **options)
        raise NotImplementedError, "#{self.class} must implement #chat"
      end
      
      def embed(text, **options)
        raise NotImplementedError, "#{self.class} must implement #embed"
      end

      private

      attr_reader :config
    end
  end
end