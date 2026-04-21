# frozen_string_literal: true

require "fileutils"

module RubyCanUseLLM
  class CLI
    COMMANDS = {
      "generate:config" => :generate_config,
      "generate:completion" => :generate_completion,
      "generate:embedding" => :generate_embedding,
      "generate:agent" => :generate_agent,
      "generate:chat" => :generate_chat
    }.freeze

    def self.start(args)
      command = args.first

      if COMMANDS.key?(command)
        new.send(COMMANDS[command])
      else
        puts "Usage: rubycanusellm <command>"
        puts ""
        puts "Commands:"
        puts "  generate:config      Generate configuration file"
        puts "  generate:completion  Generate completion service object"
        puts "  generate:embedding   Generate embedding service object"
        puts "  generate:agent       Generate agent service object with tool loop"
        puts "  generate:chat        Generate stateful chat service object with message history"
      end
    end

    def generate_config
      if rails?
        path = "config/initializers/rubycanusellm.rb"
      else
        FileUtils.mkdir_p("config")
        path = "config/llm.rb"
      end

      write_template("config", path)
    end

    def generate_completion
      if rails?
        FileUtils.mkdir_p("app/services")
        path = "app/services/completion_service.rb"
      else
        FileUtils.mkdir_p("lib")
        path = "lib/completion_service.rb"
      end

      write_template("completion", path)
    end

    def generate_embedding
      if rails?
        FileUtils.mkdir_p("app/services")
        path = "app/services/embedding_service.rb"
      else
        FileUtils.mkdir_p("lib")
        path = "lib/embedding_service.rb"
      end

      write_template("embedding", path)
    end

    def generate_agent
      if rails?
        FileUtils.mkdir_p("app/services")
        path = "app/services/agent_service.rb"
      else
        FileUtils.mkdir_p("lib")
        path = "lib/agent_service.rb"
      end

      write_template("agent", path)
    end

    def generate_chat
      if rails?
        FileUtils.mkdir_p("app/services")
        path = "app/services/chat_service.rb"
      else
        FileUtils.mkdir_p("lib")
        path = "lib/chat_service.rb"
      end

      write_template("chat", path)
    end

    private

    def rails?
      File.exist?("config/application.rb")
    end

    def write_template(name, destination)
      if File.exist?(destination)
        puts "  exists  #{destination}"
        return
      end

      template = File.read(template_path(name))
      File.write(destination, template)
      puts "  create  #{destination}"
    end

    def template_path(name)
      File.join(File.dirname(__FILE__), "templates", "#{name}.rb.tt")
    end
  end
end
