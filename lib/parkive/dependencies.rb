# frozen_string_literal: true

# @spec REN-CLI-003, REN-CLI-004, REN-CLI-005
module Parkive
  module Dependencies
    def self.poppler_installed?
      system("which pdftotext > /dev/null 2>&1")
    end

    def self.ollama_installed?
      system("which ollama > /dev/null 2>&1")
    end

    def self.ollama_running?
      system("ollama list > /dev/null 2>&1")
    end
  end
end
