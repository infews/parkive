# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe RenamePrompter do
    let(:prompt_double) { double("Prompts::TextPrompt") }

    # @spec REN-UI-001
    describe "editable prompt with original and suggested" do
      it "includes the original filename in the label" do
        allow(prompt_double).to receive(:ask).and_return("2026.01.31.Test.pdf")

        prompter = RenamePrompter.new(
          original: "quarterly-statement.pdf",
          suggested: "2026.01.31.Fidelity.12345.pdf",
          prompt: prompt_double
        )

        prompter.prompt

        expect(prompt_double).to have_received(:ask).with(
          hash_including(label: /quarterly-statement\.pdf/)
        )
      end

      it "passes suggested filename as default value" do
        allow(prompt_double).to receive(:ask).and_return("2026.01.31.Test.pdf")

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Suggested.pdf",
          prompt: prompt_double
        )

        prompter.prompt

        expect(prompt_double).to have_received(:ask).with(
          hash_including(default: "2026.01.31.Suggested.pdf")
        )
      end
    end

    # @spec REN-UI-002
    describe "rename action" do
      it "returns rename decision when user accepts suggested filename" do
        allow(prompt_double).to receive(:ask).and_return("2026.01.31.Test.pdf")

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          prompt: prompt_double
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:rename)
        expect(decision.filename).to eq("2026.01.31.Test.pdf")
      end

      it "returns rename decision with edited filename" do
        allow(prompt_double).to receive(:ask).and_return("2026.01.31.Edited.pdf")

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Original.pdf",
          prompt: prompt_double
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:rename)
        expect(decision.filename).to eq("2026.01.31.Edited.pdf")
      end
    end

    # @spec REN-UI-003, REN-UI-004
    describe "filename validation" do
      it "passes a validate lambda to the prompt" do
        validate_lambda = nil
        allow(prompt_double).to receive(:ask) do |args|
          validate_lambda = args[:validate]
          "2026.01.31.Test.pdf"
        end

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          prompt: prompt_double
        )

        prompter.prompt

        # Valid filename returns nil (no error)
        expect(validate_lambda.call("2026.01.31.Valid.pdf")).to be_nil

        # Invalid filename returns error message
        expect(validate_lambda.call("invalid.pdf")).to include("YYYY.MM.DD")

        # Empty is allowed (for skip)
        expect(validate_lambda.call("")).to be_nil
      end
    end

    # @spec REN-UI-005
    describe "skip action" do
      it "returns skip decision when user clears input" do
        allow(prompt_double).to receive(:ask).and_return("")

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          prompt: prompt_double
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:skip)
        expect(decision.filename).to be_nil
      end

      it "returns skip decision when prompt returns nil" do
        allow(prompt_double).to receive(:ask).and_return(nil)

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: "2026.01.31.Test.pdf",
          prompt: prompt_double
        )

        decision = prompter.prompt

        expect(decision.action).to eq(:skip)
        expect(decision.filename).to be_nil
      end
    end

    # @spec REN-UI-006
    describe "manual input mode" do
      it "passes empty string as default when suggested is nil" do
        allow(prompt_double).to receive(:ask).and_return("2026.01.31.Manual.pdf")

        prompter = RenamePrompter.new(
          original: "test.pdf",
          suggested: nil,
          prompt: prompt_double
        )

        prompter.prompt

        expect(prompt_double).to have_received(:ask).with(
          hash_including(default: "")
        )
      end
    end
  end
end
