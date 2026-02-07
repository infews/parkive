# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe RenamePrompter do
    # @spec REN-UI-001
    describe "display" do
      it "displays the original filename and suggested new filename" do
        output = StringIO.new
        prompter = RenamePrompter.new(
          original: "quarterly-statement.pdf",
          suggested: "2026.01.31.Fidelity.12345.pdf",
          output: output,
          input: StringIO.new("c\n")
        )

        prompter.prompt

        expect(output.string).to include("quarterly-statement.pdf")
        expect(output.string).to include("2026.01.31.Fidelity.12345.pdf")
      end
    end

    # @spec REN-UI-002
    describe "options" do
      it "offers three options: Confirm, Edit, and Skip" do
        output = StringIO.new
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          output: output,
          input: StringIO.new("c\n")
        )

        prompter.prompt

        expect(output.string).to match(/\[C\]onfirm/i)
        expect(output.string).to match(/\[E\]dit/i)
        expect(output.string).to match(/\[S\]kip/i)
      end
    end

    # @spec REN-UI-003
    describe "confirm action" do
      it "returns confirm decision with suggested filename when user chooses C" do
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          output: StringIO.new,
          input: StringIO.new("c\n")
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:confirm)
        expect(decision.filename).to eq("2026.01.31.Test.pdf")
      end
    end

    # @spec REN-UI-004
    describe "edit action" do
      it "presents an editable prompt and returns edited filename" do
        output = StringIO.new
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          output: output,
          input: StringIO.new("e\n2026.01.31.Edited.pdf\n")
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:edit)
        expect(decision.filename).to eq("2026.01.31.Edited.pdf")
      end
    end

    # @spec REN-UI-005
    describe "filename validation" do
      it "accepts filenames that conform to YYYY.MM.DD.* pattern" do
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          output: StringIO.new,
          input: StringIO.new("e\n2026.02.15.Valid.Name.pdf\n")
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:edit)
        expect(decision.filename).to eq("2026.02.15.Valid.Name.pdf")
      end
    end

    # @spec REN-UI-006
    describe "invalid filename handling" do
      it "displays error and re-prompts when filename does not conform" do
        output = StringIO.new
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          output: output,
          input: StringIO.new("e\ninvalid-name.pdf\n2026.01.31.Valid.pdf\n")
        )

        decision = prompter.prompt

        expect(output.string).to include("must start with")
        expect(decision.filename).to eq("2026.01.31.Valid.pdf")
      end
    end

    # @spec REN-UI-007
    describe "skip action" do
      it "returns skip decision with no filename when user chooses S" do
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          output: StringIO.new,
          input: StringIO.new("s\n")
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:skip)
        expect(decision.filename).to be_nil
      end
    end

    # @spec REN-UI-008
    describe "manual input mode" do
      it "prompts for manual entry when suggested is nil" do
        output = StringIO.new
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: nil,
          output: output,
          input: StringIO.new("2026.01.31.Manual.pdf\n")
        )

        decision = prompter.prompt

        expect(output.string).to include("Could not extract")
        expect(decision.action).to eq(:edit)
        expect(decision.filename).to eq("2026.01.31.Manual.pdf")
      end
    end

    # @spec REN-UI-009
    describe "manual input validation" do
      it "displays error and re-prompts when manual entry does not conform" do
        output = StringIO.new
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: nil,
          output: output,
          input: StringIO.new("bad-name.pdf\n2026.01.31.Valid.pdf\n")
        )

        decision = prompter.prompt

        expect(output.string).to include("must start with")
        expect(decision.filename).to eq("2026.01.31.Valid.pdf")
      end
    end

    # @spec REN-UI-010
    describe "skip on empty manual input" do
      it "returns skip decision when user presses Enter without input" do
        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: nil,
          output: StringIO.new,
          input: StringIO.new("\n")
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:skip)
        expect(decision.filename).to be_nil
      end
    end
  end
end
