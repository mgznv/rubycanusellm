# Changelog

## [0.5.0] - 2026-04-03

### Added

- `RubyCanUseLLM::Prompt` — lightweight prompt template system with ERB and YAML file support
- Inline prompts via `Prompt.new(system:, user:, assistant:)` + `render(**variables)`
- File-based prompts via `Prompt.load("path/to/prompt.yml", **variables)`
- Full ERB support: loops, conditionals, any Ruby expression
- Clear error messages for missing variables and invalid roles

## [0.4.1] - 2026-04-03

### Added

- Mistral provider (chat + embeddings)
- Ollama provider (chat + embeddings, local, no API key required)
- `config.base_url` for pointing to custom Ollama instances
- Mistral and Ollama added to `EMBEDDING_PROVIDERS`
- `generate:embedding` command — scaffolds an embedding service with `embed`, `similarity`, and `most_similar` methods

## [0.3.1] - 2026-04-03

### Added

- Voyage AI provider for embeddings (recommended by Anthropic)
- Configurable embedding provider (`embedding_provider`, `embedding_api_key`)
- Anthropic users can now use Voyage AI or OpenAI for embeddings
- Embedding validation with clear error messages

## [0.2.0] - 2026-04-01

### Added

- Streaming support for OpenAI and Anthropic providers via `stream: true` option and block interface
- `RubyCanUseLLM::Chunk` object yielded on each streamed token, with `content` and `role` attributes

## [0.1.0] - 2025-04-01

### Added

- Unified client interface for LLM providers
- OpenAI provider (chat completions)
- Anthropic provider (chat completions)
- Configuration module with validation
- Unified Response object with token tracking
- Error handling: AuthenticationError, RateLimitError, TimeoutError, ProviderError
- CLI with generators:
  - `generate:config` — scaffolds configuration file
  - `generate:completion` — scaffolds completion service object
- Rails and plain Ruby project detection for generators

## [0.3.0] - 2025-04-03

### Added

- Embeddings support for OpenAI provider (text-embedding-3-small)
- EmbeddingResponse object with cosine similarity helper
- `RubyCanUseLLM.embed` method