# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

module Parkive
  RSpec.describe "Commands.rename integration" do
    around(:each) do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end

    let(:temp_dir) { @temp_dir }
    let(:text_prompt) { double("Prompts::TextPrompt") }
    let(:confirm_prompt) { double("Prompts::ConfirmPrompt") }

    def create_pdf(name, content = "dummy pdf content")
      path = File.join(temp_dir, name)
      File.write(path, content)
      path
    end

    # @spec REN-FILE-001
    describe "file renaming" do
      it "renames the file when user confirms" do
        pdf_path = create_pdf("statement.pdf")

        # Mock the components
        allow(TextExtractor).to receive(:extract).and_return("Statement Date: 2026-01-15")
        allow(FieldExtractor).to receive(:extract).and_return({
          "date" => "2026.01.15",
          "vendor" => "TestBank",
          "credit_card" => "",
          "account_number" => "1234",
          "invoice_number" => ""
        })
        allow(text_prompt).to receive(:ask).and_return("2026.01.15.TestBank.1234.pdf")

        Commands.rename(
          directory: temp_dir,
          prompt: text_prompt,
          verbose: false
        )

        expect(File.exist?(File.join(temp_dir, "2026.01.15.TestBank.1234.pdf"))).to be true
        expect(File.exist?(pdf_path)).to be false
      end
    end

    # @spec REN-FILE-003
    describe "directory preservation" do
      it "keeps the file in the same directory" do
        pdf_path = create_pdf("statement.pdf")

        allow(TextExtractor).to receive(:extract).and_return("Some text")
        allow(FieldExtractor).to receive(:extract).and_return({
          "date" => "2026.01.15",
          "vendor" => "Test",
          "credit_card" => "",
          "account_number" => "",
          "invoice_number" => ""
        })
        allow(text_prompt).to receive(:ask).and_return("2026.01.15.Test.pdf")

        Commands.rename(
          directory: temp_dir,
          prompt: text_prompt,
          verbose: false
        )

        renamed_path = File.join(temp_dir, "2026.01.15.Test.pdf")
        expect(File.exist?(renamed_path)).to be true
        expect(File.dirname(renamed_path)).to eq(temp_dir)
      end
    end

    # @spec REN-FILE-002
    describe "overwrite confirmation" do
      it "prompts for confirmation when target file exists" do
        create_pdf("statement.pdf")
        create_pdf("2026.01.15.Existing.pdf", "existing content")

        allow(TextExtractor).to receive(:extract).and_return("Some text")
        allow(FieldExtractor).to receive(:extract).and_return({
          "date" => "2026.01.15",
          "vendor" => "Existing",
          "credit_card" => "",
          "account_number" => "",
          "invoice_number" => ""
        })
        allow(text_prompt).to receive(:ask).and_return("2026.01.15.Existing.pdf")
        allow(confirm_prompt).to receive(:ask).and_return(true)

        Commands.rename(
          directory: temp_dir,
          prompt: text_prompt,
          confirm_prompt: confirm_prompt,
          verbose: false
        )

        expect(confirm_prompt).to have_received(:ask).with(hash_including(label: /overwrite/i))
      end

      it "does not rename when user declines overwrite" do
        original_path = create_pdf("statement.pdf", "original content")
        existing_path = create_pdf("2026.01.15.Existing.pdf", "existing content")

        allow(TextExtractor).to receive(:extract).and_return("Some text")
        allow(FieldExtractor).to receive(:extract).and_return({
          "date" => "2026.01.15",
          "vendor" => "Existing",
          "credit_card" => "",
          "account_number" => "",
          "invoice_number" => ""
        })
        allow(text_prompt).to receive(:ask).and_return("2026.01.15.Existing.pdf")
        allow(confirm_prompt).to receive(:ask).and_return(false)

        Commands.rename(
          directory: temp_dir,
          prompt: text_prompt,
          confirm_prompt: confirm_prompt,
          verbose: false
        )

        # Original file should still exist
        expect(File.exist?(original_path)).to be true
        # Existing file should still have original content
        expect(File.read(existing_path)).to eq("existing content")
      end
    end

    # @spec REN-PROC-001
    describe "processing all PDFs" do
      it "processes all non-conforming PDFs in the directory" do
        create_pdf("doc1.pdf")
        create_pdf("doc2.pdf")
        create_pdf("2026.01.01.Already.Named.pdf") # Should be skipped

        allow(TextExtractor).to receive(:extract).and_return("Some text")
        allow(FieldExtractor).to receive(:extract).and_return({
          "date" => "2026.01.15",
          "vendor" => "Test",
          "credit_card" => "",
          "account_number" => "",
          "invoice_number" => ""
        })

        call_count = 0
        allow(text_prompt).to receive(:ask) do
          call_count += 1
          "2026.01.15.Test#{call_count}.pdf"
        end

        Commands.rename(
          directory: temp_dir,
          prompt: text_prompt,
          verbose: false
        )

        # Should have processed 2 files (not the already-named one)
        expect(call_count).to eq(2)
        expect(File.exist?(File.join(temp_dir, "2026.01.15.Test1.pdf"))).to be true
        expect(File.exist?(File.join(temp_dir, "2026.01.15.Test2.pdf"))).to be true
        expect(File.exist?(File.join(temp_dir, "2026.01.01.Already.Named.pdf"))).to be true
      end
    end
  end
end
