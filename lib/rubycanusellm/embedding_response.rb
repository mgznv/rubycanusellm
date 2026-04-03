# frozen_string_literal: true

module RubyCanUseLLM
  class EmbeddingResponse
    attr_reader :embedding, :model, :tokens, :raw

    def initialize(embedding:, model:, tokens:, raw:)
      @embedding = embedding
      @model = model
      @tokens = tokens
      @raw = raw
    end

    def cosine_similarity(other)
      dot = embedding.zip(other).sum { |a, b| a * b }
      mag_a = Math.sqrt(embedding.sum { |a| a**2 })
      mag_b = Math.sqrt(other.sum { |b| b**2 })
      return 0.0 if mag_a.zero? || mag_b.zero?

      dot / (mag_a * mag_b)
    end
  end
end