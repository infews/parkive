# frozen_string_literal: true

# @spec REN-SCAN-003, REN-SCAN-004, REN-PROC-001, REN-PROC-003, REN-FILE-001, REN-FILE-002, REN-FILE-003
module Parkive
  module Commands
    def self.rename(directory:, prompt:, confirm_prompt: nil, verbose: false)
      all_pdfs = Dir.glob(File.join(directory, "*.pdf"), File::FNM_CASEFOLD)
      raise NoPDFsFoundError.new(directory) if all_pdfs.empty?

      files_to_rename = DirectoryScanner.scan(directory)
      raise AllFilesConformingError.new(directory) if files_to_rename.empty?

      if verbose
        puts "Files to process:"
        files_to_rename.each { |f| puts "  #{File.basename(f)}" }
      end

      # @spec REN-PROC-001
      files_to_rename.each do |file_path|
        process_file(file_path, prompt: prompt, confirm_prompt: confirm_prompt, verbose: verbose)
      end
    end

    def self.process_file(file_path, prompt:, confirm_prompt: nil, verbose: false)
      original_name = File.basename(file_path)
      directory = File.dirname(file_path)

      # Extract text from PDF
      text = TextExtractor.extract(file_path)
      if text.nil? || text.empty?
        puts "Skipping #{original_name}: no text content"
        return
      end

      # Extract fields using LLM
      fields = FieldExtractor.extract(text, verbose: verbose)

      # Build suggested filename
      suggested = fields ? NameSuggestor.suggest(fields) : nil

      # Prompt user for confirmation
      prompter = RenamePrompter.new(
        original: original_name,
        suggested: suggested,
        prompt: prompt
      )
      decision = prompter.prompt

      # @spec REN-FILE-001, REN-FILE-002, REN-FILE-003
      if decision.action == :rename
        new_path = File.join(directory, decision.filename)

        # @spec REN-FILE-002
        if File.exist?(new_path) && confirm_prompt
          should_overwrite = confirm_prompt.ask(
            label: "File #{decision.filename} already exists. Overwrite?"
          )
          return unless should_overwrite
        end

        File.rename(file_path, new_path)
      end
    end
  end
end
