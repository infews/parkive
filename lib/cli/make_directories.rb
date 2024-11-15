# frozen_string_literal: true

module Parkive
  class CLI < Thor
    desc "make_directories DST", "Creates archive sub-directories in DST for the given year"
    method_option :year, default: Time.now.year.to_s, desc: "Year for folders to create"
    def make_directories(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      gum_present = `which gum`.include?("bin/gum")
      commands = Commands::Factory.forMakeDirectories(gum_present).new(destination, options[:year]).commands

      commands.each { |cmd| system cmd }
    end

    # TODO: not sure how to test this
    map mkdir: :make_directories
  end
end
