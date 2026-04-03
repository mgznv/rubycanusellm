# RubyCanUseLLM

A unified Ruby client for multiple LLM providers with generators. One interface, every LLM.

## The Problem

Every time a Ruby developer wants to add LLMs to their app, they start from scratch: pick a provider gem, learn its API, write a service object, handle errors, parse responses. Switch providers? Rewrite everything.

## The Solution

RubyCanUseLLM gives you two things:

1. **Unified client** — One interface that works the same across OpenAI, Anthropic, and more. Switch providers by changing a string, not your code.
2. **Generators** — Commands that scaffold ready-to-use boilerplate. You don't start from zero, you start with something that works.

## Installation
```bash
gem install rubycanusellm
```

Or add to your Gemfile:
```ruby
gem "rubycanusellm"
```

## Quick Start

### 1. Generate configuration
```bash
rubycanusellm generate:config
```

This creates a config file with your provider and API key. In Rails it goes to `config/initializers/rubycanusellm.rb`, otherwise to `config/llm.rb`.

### 2. Generate a completion service
```bash
rubycanusellm generate:completion
```

This creates a ready-to-use service object. In Rails it goes to `app/services/`, otherwise to `lib/`.

### 3. Use it
```ruby
RubyCanUseLLM.configure do |config|
  config.provider = :openai
  config.api_key = ENV["LLM_API_KEY"]
end

response = RubyCanUseLLM.chat([
  { role: :user, content: "What is Ruby?" }
])

puts response.content
puts "Tokens: #{response.total_tokens}"
```

### Switch providers in one line
```ruby
config.provider = :anthropic
```

That's it. Same code, different provider.

## Supported Providers

| Provider | Models | Status | Notes |
|----------|--------|--------|-------|
| OpenAI | gpt-4o-mini, gpt-4o, etc. | ✅ | Chat + Embeddings |
| Anthropic | claude-sonnet-4-20250514, etc. | ✅ | Chat only |
| Mistral | mistral-small-latest, mistral-large-latest, etc. | ✅ | Chat + Embeddings |
| Ollama | llama3.2, mistral, etc. | ✅ | Chat + Embeddings (local) |
| Voyage AI | voyage-3.5, voyage-4, etc. | ✅ | Embeddings only |

## API Reference

### Configuration
```ruby
RubyCanUseLLM.configure do |config|
  config.provider = :openai          # :openai, :anthropic, :mistral, or :ollama
  config.api_key = "your-key"        # required (not needed for Ollama)
  config.model = "gpt-4o-mini"       # optional, has sensible defaults
  config.timeout = 30                # optional, default 30s
  config.base_url = "http://localhost:11434"  # optional, for Ollama (default shown)
  config.embedding_provider = :voyage  # optional, for separate embedding provider
  config.embedding_api_key = "key"     # required when embedding_provider is set
end
```

**Ollama (local, no API key needed):**
```ruby
RubyCanUseLLM.configure do |config|
  config.provider = :ollama
  # config.base_url = "http://localhost:11434"  # default, change if needed
end
```

### Chat
```ruby
response = RubyCanUseLLM.chat(messages, **options)
```

**messages** — Array of hashes with `:role` and `:content`:
```ruby
messages = [
  { role: :system, content: "You are helpful." },
  { role: :user, content: "Hello" }
]
```

**options** — Override config per request:
```ruby
RubyCanUseLLM.chat(messages, model: "gpt-4o", temperature: 0.5)
```

### Streaming
Pass `stream: true` with a block to receive tokens as they arrive:
```ruby
RubyCanUseLLM.chat(messages, stream: true) do |chunk|
  print chunk.content
end
```

Each `chunk` is a `RubyCanUseLLM::Chunk` with `content` (the token text) and `role` (`"assistant"`). Works with OpenAI, Anthropic, Mistral, and Ollama.

### Response
```ruby
response.content       # "Hello! How can I help?"
response.model         # "gpt-4o-mini"
response.input_tokens  # 10
response.output_tokens # 5
response.total_tokens  # 15
response.raw           # original provider response
```

### Embeddings

```ruby
response = RubyCanUseLLM.embed("Hello world")
response.embedding  # [0.1, 0.2, ...]
response.tokens     # 3
response.model      # "text-embedding-3-small"
```

**OpenAI users** — embeddings work out of the box, no extra config needed:
```ruby
RubyCanUseLLM.configure do |config|
  config.provider = :openai
  config.api_key = ENV["OPENAI_API_KEY"]
end

RubyCanUseLLM.embed("Hello world")
```

**Anthropic users with Voyage AI** (recommended by Anthropic):
```ruby
RubyCanUseLLM.configure do |config|
  config.provider = :anthropic
  config.api_key = ENV["ANTHROPIC_API_KEY"]
  config.embedding_provider = :voyage
  config.embedding_api_key = ENV["VOYAGE_API_KEY"]
end

RubyCanUseLLM.embed("Hello world")
```

**Anthropic users with OpenAI for embeddings:**
```ruby
RubyCanUseLLM.configure do |config|
  config.provider = :anthropic
  config.api_key = ENV["ANTHROPIC_API_KEY"]
  config.embedding_provider = :openai
  config.embedding_api_key = ENV["OPENAI_API_KEY"]
end

RubyCanUseLLM.embed("Hello world")
```

**Cosine similarity:**
```ruby
a = RubyCanUseLLM.embed("cat")
b = RubyCanUseLLM.embed("dog")
a.cosine_similarity(b.embedding)  # 0.87
```

### Error Handling
```ruby
begin
  RubyCanUseLLM.chat(messages)
rescue RubyCanUseLLM::AuthenticationError
  # invalid API key
rescue RubyCanUseLLM::RateLimitError
  # too many requests
rescue RubyCanUseLLM::TimeoutError
  # request timed out
rescue RubyCanUseLLM::ProviderError => e
  # other provider error
end
```

## Generators

| Command | Description |
|---------|-------------|
| `rubycanusellm generate:config` | Configuration file with provider setup |
| `rubycanusellm generate:completion` | Completion service object |

## Roadmap

- [x] Project setup
- [x] Configuration module
- [x] OpenAI provider
- [x] Anthropic provider
- [x] `generate:config` command
- [x] `generate:completion` command
- [x] v0.1.0 release
- [x] Streaming support
- [x] Embeddings + configurable embedding provider
- [x] Voyage AI provider (embeddings)
- [x] Mistral provider (chat + embeddings)
- [x] Ollama provider (chat + embeddings, local)
- [x] `generate:embedding` command
- [ ] Tool calling

## Development
```bash
git clone https://github.com/mgznv/rubycanusellm.git
cd rubycanusellm
bin/setup
bundle exec rspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mgznv/rubycanusellm.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).