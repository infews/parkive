# frozen_string_literal: true

# @spec REN-SCAN-001, REN-SCAN-002
module Parkive
  class DirectoryScanner
    def self.scan(directory)
      Dir.glob(File.join(directory, "*.pdf"), File::FNM_CASEFOLD)
        .reject { |f| ArchivablePathname.new(f).is_archivable? }
    end
  end
end
