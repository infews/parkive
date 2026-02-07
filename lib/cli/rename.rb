# frozen_string_literal: true

require "prompts"

# @spec REN-CLI-001, REN-CLI-002, REN-CLI-003, REN-CLI-004, REN-CLI-005, REN-CLI-006
module Parkive
  class CLI < Thor
    desc "rename DIR", "Renames PDFs in DIR based on their content to the Parkive pattern"
    method_option :verbose, type: :boolean, default: false, desc: "Verbose output"

    def rename(directory)
      directory = File.expand_path(directory)
      raise NoSourceDirectoryError.new(directory) unless Dir.exist?(directory)
      raise PopplerNotInstalledError.new unless Dependencies.poppler_installed?
      raise OllamaNotInstalledError.new unless Dependencies.ollama_installed?
      raise OllamaNotRunningError.new unless Dependencies.ollama_running?

      Commands.rename(
        directory: directory,
        prompt: Prompts::TextPrompt,
        confirm_prompt: Prompts::ConfirmPrompt,
        verbose: options[:verbose]
      )
    end
  end
end
