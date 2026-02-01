# frozen_string_literal: true

# @spec REN-CLI-001, REN-CLI-002, REN-CLI-003, REN-CLI-004, REN-CLI-005
module Parkive
  class CLI < Thor
    desc "rename DIR", "Renames PDFs in DIR based on their content to the Parkive pattern"

    def rename(directory)
      raise NoSourceDirectoryError.new(directory) unless Dir.exist?(directory)
      raise PopplerNotInstalledError.new unless Dependencies.poppler_installed?
      raise OllamaNotInstalledError.new unless Dependencies.ollama_installed?
      raise OllamaNotRunningError.new unless Dependencies.ollama_running?
    end
  end
end
