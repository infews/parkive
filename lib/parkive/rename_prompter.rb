# frozen_string_literal: true

# @spec REN-UI-001 through REN-UI-010
module Parkive
  class RenamePrompter
    DATE_PATTERN = /^\d{4}\.\d{2}\.\d{2}\./

    def initialize(original:, suggested:, prompt:)
      @original = original
      @suggested = suggested
      @prompt = prompt
    end

    def prompt
      result = @prompt.ask(
        label: "Rename #{@original} to:",
        default: @suggested || "",
        hint: "Press Enter to accept, edit to change, or clear to skip",
        validate: ->(value) { validate_filename(value) }
      )

      if result.nil? || result.empty?
        RenameDecision.new(action: :skip, filename: nil)
      else
        RenameDecision.new(action: :rename, filename: result)
      end
    end

    private

    def validate_filename(filename)
      return nil if filename.nil? || filename.empty? # Allow empty to skip
      return nil if filename.match?(DATE_PATTERN)    # Valid format

      "Filename must start with YYYY.MM.DD format"
    end
  end

  RenameDecision = Struct.new(:action, :filename, keyword_init: true)
end
