# frozen_string_literal: true

module Parkive
  module Commands
    def self.store(source_paths:, archive_root:, prompt:, verbose: false, force: false)
      archivable_paths = ArchivablePathname.from(source_paths)
      raise NoArchivableFilesFoundError.new(source_paths) if archivable_paths.empty?

      a = Archiver.new(paths: archivable_paths, archive_root: archive_root, verbose: verbose)

      a.store_all and return if force

      a.store { |path| !File.exist?(File.join(archive_root, path.archive_path, path.basename)) }
        .collect { |path| path.move = prompt.ask(label: overwrite_prompt(archive_root, path)) }
        .store { |path| path.move? }
    end

    def self.overwrite_prompt(archive_root, path)
      "File #{File.join(archive_root, path.archive_path, path.basename)} exists in archive. Overwrite?"
    end
  end
end
