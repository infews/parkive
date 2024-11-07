# frozen_string_literal: true

require_relative "parkive/version"
require_relative "cli"

module Parkive
  class NoDestinationDirectoryError < StandardError
    def initialize(path)
      super "Destination directory #{path} does not exist"
    end
  end
end
