# RubyCanUseLLM

A unified Ruby client for multiple LLM providers with generators. One interface, every LLM.

## The Problem

Every time a Ruby developer wants to add LLMs to their app, they start from scratch: pick a provider gem, learn its API, write a service object, handle errors, parse responses. Switch providers? Rewrite everything.

## The Solution

RubyCanUseLLM gives you two things:

1. **Unified client** — One interface that works the same across OpenAI, Anthropic, and more. Switch providers by changing a string, not your code.
2. **Generators** — Commands that scaffold ready-to-use boilerplate. You don't start from zero, you start with something that works.

## Quick Start
```bash
gem install rubycanusellm

rubycanusellm generate:config
rubycanusellm generate:completion
```

That's it. You have a working completion service in your project.

## Roadmap

- [x] Project setup
- [x] Configuration module
- [x] OpenAI provider
- [x] Anthropic provider
- [ ] `generate:config` command
- [ ] `generate:completion` command
- [ ] v0.1.0 release

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