# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe "Parkive::CLI#rename" do
    # @spec REN-CLI-001
    context "when no directory is provided" do
      it "fails with a usage error" do
        expect do
          CLI.new.invoke(:rename)
        end.to raise_error(Thor::InvocationError)
      end
    end

    # @spec REN-CLI-002
    context "when the directory does not exist" do
      it "fails with a useful error" do
        expect do
          CLI.new.invoke(:rename, ["nonexistent_directory"])
        end.to raise_error(NoSourceDirectoryError)
      end
    end

    context "when the directory exists" do
      around :each do |example|
        Dir.mktmpdir do |dir|
          @temp_dir = dir
          example.run
        end
      end
      let(:temp_dir) { @temp_dir }

      # @spec REN-CLI-003
      context "when Poppler is not installed" do
        it "fails with a useful error" do
          allow(Dependencies).to receive(:poppler_installed?).and_return(false)
          expect do
            CLI.new.invoke(:rename, [temp_dir])
          end.to raise_error(PopplerNotInstalledError)
        end
      end

      # @spec REN-CLI-004
      context "when Ollama is not installed" do
        it "fails with a useful error" do
          allow(Dependencies).to receive(:poppler_installed?).and_return(true)
          allow(Dependencies).to receive(:ollama_installed?).and_return(false)
          expect do
            CLI.new.invoke(:rename, [temp_dir])
          end.to raise_error(OllamaNotInstalledError)
        end
      end

      # @spec REN-CLI-005
      context "when Ollama is not running" do
        it "fails with a useful error" do
          allow(Dependencies).to receive(:poppler_installed?).and_return(true)
          allow(Dependencies).to receive(:ollama_installed?).and_return(true)
          allow(Dependencies).to receive(:ollama_running?).and_return(false)
          expect do
            CLI.new.invoke(:rename, [temp_dir])
          end.to raise_error(OllamaNotRunningError)
        end
      end

      context "when all dependencies are met" do
        before do
          allow(Dependencies).to receive(:poppler_installed?).and_return(true)
          allow(Dependencies).to receive(:ollama_installed?).and_return(true)
          allow(Dependencies).to receive(:ollama_running?).and_return(true)
        end

        # @spec REN-CLI-006
        context "when the --verbose flag is provided" do
          it "passes verbose mode to Commands.rename" do
            expect(Commands).to receive(:rename).with(
              directory: temp_dir,
              verbose: true
            )
            CLI.new.invoke(:rename, [temp_dir], { verbose: true })
          end
        end

        context "when the --verbose flag is not provided" do
          it "passes verbose as false to Commands.rename" do
            expect(Commands).to receive(:rename).with(
              directory: temp_dir,
              verbose: false
            )
            CLI.new.invoke(:rename, [temp_dir])
          end
        end
      end
    end
  end
end
