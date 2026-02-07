require_relative "parkive/version"
require_relative "parkive/commands"
require_relative "parkive/archivable_pathname"
require_relative "parkive/archiver"
require_relative "parkive/dependencies"
require_relative "parkive/directory_scanner"
require_relative "parkive/text_extractor"
require_relative "parkive/field_extractor"
require_relative "parkive/name_suggestor"
require_relative "parkive/rename_prompter"
require_relative "cli"

module Parkive
  DATE_PATTERN = /^(\d{4}\.\d{2}\.\d{2})/

  class NoDestinationDirectoryError < Thor::Error
    def initialize(path)
      message = "Destination directory \"#{path}\" does not exist."
      super(message)
    end
  end

  class NoArchivableFilesFoundError < Thor::Error
    def initialize(paths)
      message = "No archivable files found."
      if paths.first
        pn = Pathname(paths.first)
        message.insert(-2, " at \"#{pn.dirname}\"")
      end
      super(message)
    end
  end

  # @spec REN-CLI-002
  class NoSourceDirectoryError < Thor::Error
    def initialize(path)
      message = "Source directory \"#{path}\" does not exist."
      super(message)
    end
  end

  # @spec REN-CLI-003
  class PopplerNotInstalledError < Thor::Error
    def initialize
      message = "Poppler is not installed. Please install it with: brew install poppler"
      super(message)
    end
  end

  # @spec REN-CLI-004
  class OllamaNotInstalledError < Thor::Error
    def initialize
      message = "Ollama is not installed. Please install it from https://ollama.ai and run: ollama pull llama3.1:8b"
      super(message)
    end
  end

  # @spec REN-CLI-005
  class OllamaNotRunningError < Thor::Error
    def initialize
      message = "Ollama is not running. Please start it with: ollama serve"
      super(message)
    end
  end

  # @spec REN-SCAN-003
  class NoPDFsFoundError < Thor::Error
    def initialize(directory)
      message = "No PDFs found in \"#{directory}\"."
      super(message)
    end
  end

  # @spec REN-SCAN-004
  class AllFilesConformingError < Thor::Error
    def initialize(directory)
      message = "All files already named as expected in \"#{directory}\"."
      super(message)
    end
  end
end
