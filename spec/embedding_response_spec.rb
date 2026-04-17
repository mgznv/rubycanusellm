# frozen_string_literal: true

RSpec.describe RubyCanUseLLM::EmbeddingResponse do
  describe "#cosine_similarity" do
    it "returns 1.0 for identical vectors" do
      response = described_class.new(
        embedding: [1.0, 0.0, 0.0],
        model: "test",
        tokens: 1,
        raw: {}
      )

      expect(response.cosine_similarity([1.0, 0.0, 0.0])).to be_within(0.001).of(1.0)
    end

    it "returns 0.0 for orthogonal vectors" do
      response = described_class.new(
        embedding: [1.0, 0.0],
        model: "test",
        tokens: 1,
        raw: {}
      )

      expect(response.cosine_similarity([0.0, 1.0])).to be_within(0.001).of(0.0)
    end
  end
end
