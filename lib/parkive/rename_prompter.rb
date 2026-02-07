# frozen_string_literal: true

# @spec REN-UI-001
module Parkive
  class RenamePrompter
    DATE_PATTERN = /^\d{4}\.\d{2}\.\d{2}\./

    def initialize(original:, suggested:, output: $stdout, input: $stdin)
      @original = original
      @suggested = suggested
      @output = output
      @input = input
    end

    # @spec REN-UI-002, REN-UI-003, REN-UI-004, REN-UI-008
    def prompt
      @output.puts "Original:  #{@original}"

      # @spec REN-UI-008
      if @suggested.nil?
        @output.puts "Could not extract fields automatically."
        @output.puts
        return prompt_for_manual_entry
      end

      @output.puts "Suggested: #{@suggested}"
      @output.puts
      @output.puts "[C]onfirm  [E]dit  [S]kip"

      choice = @input.gets.to_s.strip.downcase

      case choice
      when "c"
        RenameDecision.new(action: :confirm, filename: @suggested)
      when "e"
        prompt_for_filename
      when "s"
        RenameDecision.new(action: :skip, filename: nil)
      else
        RenameDecision.new(action: :confirm, filename: @suggested)
      end
    end

    private

    # @spec REN-UI-005, REN-UI-006, REN-UI-010
    def prompt_for_filename(allow_empty_skip: false)
      loop do
        @output.print "Enter new filename: "
        new_filename = @input.gets.to_s.strip

        # @spec REN-UI-010
        if allow_empty_skip && new_filename.empty?
          return RenameDecision.new(action: :skip, filename: nil)
        end

        if valid_filename?(new_filename)
          return RenameDecision.new(action: :edit, filename: new_filename)
        else
          @output.puts "Error: Filename must start with YYYY.MM.DD format"
        end
      end
    end

    def valid_filename?(filename)
      filename.match?(DATE_PATTERN)
    end

    # @spec REN-UI-008, REN-UI-010
    def prompt_for_manual_entry
      prompt_for_filename(allow_empty_skip: true)
    end
  end

  RenameDecision = Struct.new(:action, :filename, keyword_init: true)
end
