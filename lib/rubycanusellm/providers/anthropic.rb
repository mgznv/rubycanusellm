# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module RubyCanUseLLM
  module Providers
    class Anthropic < Base
      API_URL = "https://api.anthropic.com/v1/messages"

      def chat(messages, **options, &block)
        system, user_messages = extract_system(messages)
        if options[:stream] && block
          body = build_body(system, user_messages, options.except(:stream)).merge(stream: true)
          stream_request(body, &block)
        else
          body = build_body(system, user_messages, options)
          response = request(body)
          parse_response(response)
        end
      end

      private

      def extract_system(messages)
        system = nil
        user_messages = []

        messages.each do |msg|
          if msg[:role].to_s == "system"
            system = msg[:content]
          else
            user_messages << msg
          end
        end

        [system, user_messages]
      end

      def build_body(system, messages, options)
        body = {
          model: options[:model] || config.model || "claude-sonnet-4-20250514",
          messages: format_messages(messages),
          max_tokens: options[:max_tokens] || 1024
        }
        body[:system] = system if system
        body
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
        req["x-api-key"] = config.api_key
        req["anthropic-version"] = "2023-06-01"
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        handle_response(http.request(req))
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to Anthropic timed out after #{config.timeout}s"
      end

      def stream_request(body, &block)
        uri = URI(API_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = config.timeout

        req = Net::HTTP::Post.new(uri)
        req["x-api-key"] = config.api_key
        req["anthropic-version"] = "2023-06-01"
        req["Content-Type"] = "application/json"
        req["Accept-Encoding"] = "identity"
        req.body = body.to_json

        http.request(req) do |response|
          case response.code.to_i
          when 401 then raise AuthenticationError, "Invalid Anthropic API key"
          when 429 then raise RateLimitError, "Anthropic rate limit exceeded"
          end
          raise ProviderError, "Anthropic error (#{response.code})" unless response.code.to_i == 200

          buffer = ""
          current_event = nil

          response.read_body do |raw_chunk|
            buffer += raw_chunk
            lines = buffer.split("\n", -1)
            buffer = lines.pop || ""
            lines.each do |line|
              line.chomp!
              if line.start_with?("event: ")
                current_event = line[7..]
              elsif line.start_with?("data: ")
                next unless current_event == "content_block_delta"

                parsed = JSON.parse(line[6..])
                text = parsed.dig("delta", "text")
                block.call(Chunk.new(content: text)) if text
              end
            end
          end
        end
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to Anthropic timed out after #{config.timeout}s"
      end

      def handle_response(response)
        case response.code.to_i
        when 200
          JSON.parse(response.body)
        when 401
          raise AuthenticationError, "Invalid Anthropic API key"
        when 429
          raise RateLimitError, "Anthropic rate limit exceeded"
        else
          raise ProviderError, "Anthropic error (#{response.code}): #{response.body}"
        end
      end

      def parse_response(data)
        content = data.dig("content", 0, "text")
        usage = data["usage"]

        Response.new(
          content: content,
          model: data["model"],
          input_tokens: usage["input_tokens"],
          output_tokens: usage["output_tokens"],
          raw: data
        )
      end
    end
  end
end
