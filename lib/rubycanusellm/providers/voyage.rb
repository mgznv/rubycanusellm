# frozen_string_literal: true

require "net/http"
require "json"

module RubyCanUseLLM
  module Providers
    class Voyage < Base
      API_URL = "https://api.voyageai.com/v1/embeddings"

      def chat(_messages, **_options)
        raise Error, "Voyage AI only supports embeddings, not chat completions"
      end

      def embed(text, **options)
        body = {
          model: options[:model] || "voyage-3.5",
          input: text
        }
        response = embedding_request(body)
        parse_embedding(response)
      end

      private

      def embedding_request(body)
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
        raise TimeoutError, "Request to Voyage AI timed out after #{config.timeout}s"
      end

      def handle_response(response)
        case response.code.to_i
        when 200
          JSON.parse(response.body)
        when 401
          raise AuthenticationError, "Invalid Voyage AI API key"
        when 429
          raise RateLimitError, "Voyage AI rate limit exceeded"
        else
          raise ProviderError, "Voyage AI error (#{response.code}): #{response.body}"
        end
      end

      def parse_embedding(data)
        embedding = data.dig("data", 0, "embedding")
        usage = data["usage"]

        EmbeddingResponse.new(
          embedding: embedding,
          model: data["model"],
          tokens: usage["total_tokens"],
          raw: data
        )
      end
    end
  end
end
