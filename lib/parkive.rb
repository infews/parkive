require_relative "parkive/version"
require_relative "parkive/commands"
require_relative "parkive/archivable_pathname"
require_relative "parkive/archiver"
require_relative "cli"

module Parkive
  class NoDestinationDirectoryError < Thor::Error
    def initialize(path)
      super("Destination directory \"#{path}\" does not exist.")
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

  DATE_PATTERN = /^(\d{4}\.\d{2}\.\d{2})/
end
