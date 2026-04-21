# Changelog

## [0.9.0] - 2026-04-21

### Added

- `response_format: :json` option for `RubyCanUseLLM.chat` — requests structured JSON output from the model
- `Response#parsed` — parses `content` as JSON and returns a Hash
- OpenAI and Mistral: sends `response_format: { type: "json_object" }` natively
- Ollama: sends `format: "json"` natively
- Anthropic: injects a JSON instruction into the system prompt (no native JSON mode)

## [0.8.0] - 2026-04-21

### Added

- `generate:chat` — scaffolds a stateful `ChatService` with message history
- `ChatService#say(message)` — sends a message and appends both user and assistant turns to history
- `ChatService#reset!` — clears history while preserving the system prompt
- `ChatService#history` — returns a copy of the current message array
- Optional `system_prompt:` argument on `ChatService.new`

## [0.7.0] - 2026-04-21

### Added

- `generate:agent` — scaffolds an `AgentService` with a full tool loop
- Agent handles the `assistant → tool → chat` message cycle automatically up to `MAX_ITERATIONS`
- `dispatch(name, arguments)` method as the single extension point for connecting tools
- CLI help text updated to include the new command

## [0.6.0] - 2026-04-10

### Added

- Tool calling support for OpenAI, Anthropic, Mistral, and Ollama providers
- `RubyCanUseLLM::ToolCall` object with `id`, `name`, and `arguments` (parsed Hash)
- `Response#tool_calls` — array of `ToolCall` objects when the model requests a tool, `nil` otherwise
- `Response#tool_call?` — convenience predicate
- Unified tool definition format: `[{ name:, description:, parameters: }]` — providers handle format translation internally
- Anthropic's `tool_use`/`tool_result` format handled transparently
- Multi-turn tool use: send `role: :tool` messages with `tool_call_id:` and `content:` to continue the conversation

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