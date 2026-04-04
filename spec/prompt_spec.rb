# frozen_string_literal: true

require "tempfile"

RSpec.describe RubyCanUseLLM::Prompt do
  describe ".new + #render" do
    it "renders a simple user prompt" do
      prompt = described_class.new(user: "Hello <%= name %>")
      messages = prompt.render(name: "world")

      expect(messages).to eq([{ role: :user, content: "Hello world" }])
    end

    it "renders system and user roles" do
      prompt = described_class.new(
        system: "You are a <%= role %> expert.",
        user: "Analyze: <%= item %>"
      )
      messages = prompt.render(role: "electronics", item: "capacitor")

      expect(messages).to eq([
        { role: :system, content: "You are a electronics expert." },
        { role: :user, content: "Analyze: capacitor" }
      ])
    end

    it "renders ERB loops" do
      prompt = described_class.new(
        user: "Items:\n<% items.each do |i| %>\n- <%= i %>\n<% end %>"
      )
      messages = prompt.render(items: ["one", "two", "three"])

      expect(messages.first[:content]).to include("- one")
      expect(messages.first[:content]).to include("- two")
      expect(messages.first[:content]).to include("- three")
    end

    it "renders ERB conditionals" do
      prompt = described_class.new(
        user: "Hello<% if formal %> sir<% end %>."
      )

      expect(prompt.render(formal: true).first[:content]).to eq("Hello sir.")
      expect(prompt.render(formal: false).first[:content]).to eq("Hello.")
    end

    it "raises an error when a required variable is missing" do
      prompt = described_class.new(user: "Hello <%= name %>")

      expect { prompt.render }
        .to raise_error(RubyCanUseLLM::Error, /Missing variable.*name/)
    end

    it "raises an error when :user role is missing" do
      expect { described_class.new(system: "You are helpful.") }
        .to raise_error(RubyCanUseLLM::Error, /requires at least a :user role/)
    end

    it "raises an error for invalid roles" do
      expect { described_class.new(user: "Hi", admin: "nope") }
        .to raise_error(RubyCanUseLLM::Error, /Invalid role/)
    end

    it "omits nil or blank roles from output" do
      prompt = described_class.new(system: nil, user: "Hi")
      messages = prompt.render

      expect(messages.map { |m| m[:role] }).to eq([:user])
    end
  end

  describe ".load" do
    let(:tmpfile) { Tempfile.new(["prompt", ".yml"]) }

    after { tmpfile.unlink }

    it "loads and renders a YAML prompt file" do
      tmpfile.write(<<~YAML)
        system: "You are a <%= domain %> expert."
        user: "Analyze: <%= description %>"
      YAML
      tmpfile.flush

      messages = described_class.load(tmpfile.path,
        domain: "electronics",
        description: "capacitor 10uF"
      )

      expect(messages).to eq([
        { role: :system, content: "You are a electronics expert." },
        { role: :user, content: "Analyze: capacitor 10uF" }
      ])
    end

    it "supports ERB loops in YAML files" do
      tmpfile.write(<<~YAML)
        user: |
          References:
          <% refs.each do |r| -%>
          - <%= r %>
          <% end -%>
      YAML
      tmpfile.flush

      messages = described_class.load(tmpfile.path, refs: ["ceramic", "electrolytic"])

      expect(messages.first[:content]).to include("- ceramic")
      expect(messages.first[:content]).to include("- electrolytic")
    end

    it "raises an error when the file does not exist" do
      expect { described_class.load("nonexistent.yml") }
        .to raise_error(RubyCanUseLLM::Error, /not found/)
    end

    it "raises an error for missing variables in file" do
      tmpfile.write("user: \"Hello <%= name %>\"")
      tmpfile.flush

      expect { described_class.load(tmpfile.path) }
        .to raise_error(RubyCanUseLLM::Error, /Missing variable/)
    end
  end
end
