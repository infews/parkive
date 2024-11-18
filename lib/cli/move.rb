# frozen_string_literal: true

require "prompts"

module Parkive
  class CLI < Thor
    desc "move DST", "Moves files that match the archive naming format to the destination"
    method_option :source, type: :string, default: ".", desc: "Source directory for archivable files"
    method_option :force, type: :boolean, default: false, desc: "Force overwrite files at archive root"

    def move(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      Parkive::Commands.move(source_paths: Dir.glob(File.join(options[:source], "*")),
        archive_root: destination,
        prompt: Prompts::ConfirmPrompt,
        force: options[:force])
    end

    # TODO: not sure how to test this
    map mv: :move
  end
end
