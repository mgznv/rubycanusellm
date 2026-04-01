# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module RubyCanUseLLM
  module Providers
    class OpenAI < Base
      API_URL = "https://api.openai.com/v1/chat/completions"

      def chat(messages, **options, &block)
        if options[:stream] && block
          body = build_body(messages, options.except(:stream)).merge(stream: true)
          stream_request(body, &block)
        else
          body = build_body(messages, options)
          response = request(body)
          parse_response(response)
        end
      end

      private

      def build_body(messages, options)
        {
          model: options[:model] || config.model || "gpt-4o-mini",
          messages: format_messages(messages),
          temperature: options[:temperature] || 0.7
        }
      end

      def format_messages(messages)
        messages.map do |msg|
          { role: msg[:role].to_s, content: msg[:content] }
        end
      end

      def request(body)
        uri = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = config.timeout

        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{config.api_key}"
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        handle_response(http.request(req))
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to OpenAI timed out after #{config.timeout}s"
      end

      def stream_request(body, &block)
        uri = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = config.timeout

        req = Net::HTTP::Post.new(uri)
        req["Authorization"] = "Bearer #{config.api_key}"
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        http.request(req) do |response|
          case response.code.to_i
          when 401 then raise AuthenticationError, "Invalid OpenAI API key"
          when 429 then raise RateLimitError, "OpenAI rate limit exceeded"
          end
          raise ProviderError, "OpenAI error (#{response.code})" unless response.code.to_i == 200

          buffer = ""
          response.read_body do |raw_chunk|
            buffer += raw_chunk
            lines = buffer.split("\n", -1)
            buffer = lines.pop || ""
            lines.each do |line|
              line.chomp!
              next unless line.start_with?("data: ")

              data = line[6..]
              next if data == "[DONE]"

              parsed = JSON.parse(data)
              content = parsed.dig("choices", 0, "delta", "content")
              block.call(Chunk.new(content: content)) if content && !content.empty?
            end
          end
        end
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to OpenAI timed out after #{config.timeout}s"
      end

      def handle_response(response)
        case response.code.to_i
        when 200
          JSON.parse(response.body)
        when 401
          raise AuthenticationError, "Invalid OpenAI API key"
        when 429
          raise RateLimitError, "OpenAI rate limit exceeded"
        else
          raise ProviderError, "OpenAI error (#{response.code}): #{response.body}"
        end
      end

      def parse_response(data)
        choice = data.dig("choices", 0, "message")
        usage = data["usage"]

        Response.new(
          content: choice["content"],
          model: data["model"],
          input_tokens: usage["prompt_tokens"],
          output_tokens: usage["completion_tokens"],
          raw: data
        )
      end
    end
  end
end
