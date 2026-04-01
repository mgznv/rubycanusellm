# Changelog

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