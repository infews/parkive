# frozen_string_literal: true

module Parkive
  class CLI < Thor
    desc "move DST", "Moves files that match the archive naming format to the destination"
    # method_option :year, default: Time.now.year.to_s, desc: "Year for folders to create"
    def move(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      # gum_present = `which gum`.include?("bin/gum")
      # commands = Commands::Factory.forMakeDirectories(gum_present).new(destination, options[:year]).commands
      #
      # commands.each { |cmd| system cmd }
    end

    # TODO: not sure how to test this
    map mv: :move
  end
end
