# frozen_string_literal: true

require_relative "parkive/version"
require_relative "parkive/commands"
require_relative "parkive/archivable_pathname"
require_relative "parkive/archiver"
require_relative "cli"

module Parkive
  class NoDestinationDirectoryError < Thor::Error
    def initialize(path)
      super("Destination directory '#{path}' does not exist.")
    end
  end

  DATE_PATTERN = /^(\d{4}\.\d{2}\.\d{2})/
end
