# frozen_string_literal: true

module Parkive
  class CLI < Thor
    desc "move DST", "Moves files that match the archive naming format to the destination"
    method_option :source, type: :string, default: ".", desc: "Source directory for files"

    def move(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      source_paths = ArchivablePathname.from(Dir.glob(File.join(options[:source], "*")))
      Archiver.new(source_paths, destination)
        .move_if { |path| path.is_archivable? }
    end

    # TODO: not sure how to test this
    map mv: :move
  end
end
