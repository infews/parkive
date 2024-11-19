# frozen_string_literal: true

module Parkive
  module Commands
    def self.move(source_paths:, archive_root:, prompt:, verbose: false, force: false)
      archivable_paths = ArchivablePathname.from(source_paths)
      a = Archiver.new(paths: archivable_paths, archive_root: archive_root, verbose: verbose)

      if force
        a.move { true }
      else
        a.move { |path| !File.exist?(File.join(archive_root, path.archive_path, path.basename)) }
          .collect { |path| path.move = prompt.ask(label: "File #{File.join(archive_root, path.archive_path, path.basename)} exists. Overwrite?") }
          .move { |path| path.move? }
      end
      # .log
    end
  end
end
