# frozen_string_literal: true

require "prompts"

module Parkive
  class CLI < Thor
    desc "store DST", "Stores files that match the archive naming format to the destination "
    method_option :source, type: :string, default: ".", desc: "Source directory for archivable files"
    method_option :force, type: :boolean, default: false, desc: "Force overwrite files at archive root"
    method_option :verbose, type: :boolean, default: false, desc: "Verbose output"

    def store(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      Parkive::Commands.store(
        source_paths: Dir.glob(File.join(options[:source], "*")).sort,
        archive_root: destination,
        prompt: Prompts::ConfirmPrompt,
        verbose: options[:verbose],
        force: options[:force]
      )
    end

    # TODO: not sure how to test this
    map mv: :move
  end
end
