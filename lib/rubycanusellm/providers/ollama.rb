# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module RubyCanUseLLM
  module Providers
    class Ollama < Base
      DEFAULT_BASE_URL = "http://localhost:11434"

      def chat(messages, **options, &block)
        if options[:stream] && block
          body = build_body(messages, options.except(:stream)).merge(stream: true)
          stream_request(body, &block)
        else
          body = build_body(messages, options).merge(stream: false)
          response = request(body)
          parse_response(response)
        end
      end

      def embed(text, **options)
        body = {
          model: options[:model] || "nomic-embed-text",
          input: text
        }
        response = embedding_request(body)
        parse_embedding(response)
      end

      private

      def base_url
        config.base_url || DEFAULT_BASE_URL
      end

      def build_body(messages, options)
        body = {
          model: options[:model] || config.model || "llama3.2",
          messages: format_messages(messages),
          temperature: options[:temperature] || 0.7
        }
        body[:tools] = format_tools(options[:tools]) if options[:tools]
        body
      end

      def format_messages(messages)
        messages.map do |msg|
          case msg[:role].to_s
          when "tool"
            { role: "tool", content: msg[:content].to_s }
          when "assistant"
            m = { role: "assistant", content: msg[:content] || "" }
            if msg[:tool_calls]
              m[:tool_calls] = msg[:tool_calls].map do |tc|
                { function: { name: tc.name, arguments: tc.arguments } }
              end
            end
            m
          else
            { role: msg[:role].to_s, content: msg[:content] }
          end
        end
      end

      def format_tools(tools)
        tools.map do |t|
          { type: "function", function: { name: t[:name], description: t[:description], parameters: t[:parameters] } }
        end
      end

      def request(body)
        uri = URI("#{base_url}/api/chat")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = config.timeout

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        handle_response(http.request(req))
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to Ollama timed out after #{config.timeout}s"
      end

      def stream_request(body, &block)
        uri = URI("#{base_url}/api/chat")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = config.timeout

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req["Accept-Encoding"] = "identity"
        req.body = body.to_json

        http.request(req) do |response|
          raise ProviderError, "Ollama error (#{response.code})" unless response.code.to_i == 200

          response.read_body do |raw_chunk|
            raw_chunk.split("\n").each do |line|
              line.strip!
              next if line.empty?

              parsed = JSON.parse(line)
              content = parsed.dig("message", "content")
              block.call(Chunk.new(content: content)) if content && !content.empty? && !parsed["done"]
            end
          end
        end
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to Ollama timed out after #{config.timeout}s"
      end

      def handle_response(response)
        case response.code.to_i
        when 200
          JSON.parse(response.body)
        else
          raise ProviderError, "Ollama error (#{response.code}): #{response.body}"
        end
      end

      def parse_response(data)
        message = data["message"]

        tool_calls = nil
        if message["tool_calls"]
          tool_calls = message["tool_calls"].each_with_index.map do |tc, i|
            ToolCall.new(
              id: "call_#{i}",
              name: tc.dig("function", "name"),
              arguments: tc.dig("function", "arguments") || {}
            )
          end
        end

        Response.new(
          content: message["content"],
          model: data["model"],
          input_tokens: data["prompt_eval_count"] || 0,
          output_tokens: data["eval_count"] || 0,
          tool_calls: tool_calls,
          raw: data
        )
      end

      def embedding_request(body)
        uri = URI("#{base_url}/api/embed")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = config.timeout

        req = Net::HTTP::Post.new(uri)
        req["Content-Type"] = "application/json"
        req.body = body.to_json

        handle_response(http.request(req))
      rescue Net::ReadTimeout, Net::OpenTimeout
        raise TimeoutError, "Request to Ollama timed out after #{config.timeout}s"
      end

      def parse_embedding(data)
        embedding = data.dig("embeddings", 0)
        EmbeddingResponse.new(
          embedding: embedding,
          model: data["model"],
          tokens: data["prompt_eval_count"] || 0,
          raw: data
        )
      end
    end
  end
end
