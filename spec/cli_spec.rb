# frozen_string_literal: true

require "tmpdir"

RSpec.describe RubyCanUseLLM::CLI do
  around do |example|
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) { example.run }
    end
  end

  describe "generate:agent" do
    context "in a plain Ruby project" do
      it "creates lib/agent_service.rb" do
        described_class.start(["generate:agent"])
        expect(File).to exist("lib/agent_service.rb")
      end

      it "scaffolds AgentService with TOOLS, MAX_ITERATIONS, call, and dispatch" do
        described_class.start(["generate:agent"])
        content = File.read("lib/agent_service.rb")

        expect(content).to include("class AgentService")
        expect(content).to include("MAX_ITERATIONS")
        expect(content).to include("TOOLS")
        expect(content).to include("def call")
        expect(content).to include("def dispatch")
        expect(content).to include("RubyCanUseLLM.chat")
        expect(content).to include("role: :tool")
      end

      it "does not overwrite an existing file" do
        FileUtils.mkdir_p("lib")
        File.write("lib/agent_service.rb", "# existing")
        described_class.start(["generate:agent"])
        expect(File.read("lib/agent_service.rb")).to eq("# existing")
      end
    end

    context "in a Rails project" do
      before do
        FileUtils.mkdir_p("config")
        File.write("config/application.rb", "# rails")
      end

      it "creates app/services/agent_service.rb" do
        described_class.start(["generate:agent"])
        expect(File).to exist("app/services/agent_service.rb")
      end
    end
  end

  describe "unknown command" do
    it "prints usage info" do
      expect { described_class.start(["unknown"]) }.to output(/generate:agent/).to_stdout
    end
  end
end
