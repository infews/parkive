require_relative "parkive/version"
require_relative "parkive/commands"
require_relative "parkive/archivable_pathname"
require_relative "parkive/archiver"
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
end
