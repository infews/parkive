# frozen_string_literal: true

# @spec REN-SCAN-003, REN-SCAN-004, REN-PROC-003
module Parkive
  module Commands
    def self.rename(directory:, verbose: false)
      all_pdfs = Dir.glob(File.join(directory, "*.pdf"), File::FNM_CASEFOLD)
      raise NoPDFsFoundError.new(directory) if all_pdfs.empty?

      files_to_rename = DirectoryScanner.scan(directory)
      raise AllFilesConformingError.new(directory) if files_to_rename.empty?

      if verbose
        puts "Files to process:"
        files_to_rename.each { |f| puts "  #{File.basename(f)}" }
      end
    end
  end
end
