# frozen_string_literal: true

module Parkive
  class CLI < Thor
    desc "make_directories DST", "Creates archive sub-directories in DST for the given year"
    method_option :year, default: Time.now.year.to_s, desc: "Year for folders to create"
    method_option :verbose, type: :boolean, default: false, desc: "Verbose output"

    def make_directories(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      Parkive::Commands.make_directories(archive_root: destination,
        year: options[:year],
        verbose: options[:verbose])
    end

    # TODO: not sure how to test this
    map mkdir: :make_directories
  end
end
