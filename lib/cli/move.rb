# frozen_string_literal: true

module Parkive
  class CLI < Thor
    desc "move DST", "Moves files that match the archive naming format to the destination"
    method_option :source, type: :string, default: ".", desc: "Source directory for files"
    def move(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      paths = ArchivablePathname.from(Dir.glob(File.join(options[:source], "*")))

      paths.each do |path|
        FileUtils::Verbose.move(path, File.join(destination, path.archive_path))
      end
    end

    # TODO: not sure how to test this
    map mv: :move
  end
end
