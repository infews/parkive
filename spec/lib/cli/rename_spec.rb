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
    end
  end
end
