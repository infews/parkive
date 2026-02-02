# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe "Parkive::Commands.rename" do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }

    # @spec REN-SCAN-003
    describe "when no PDF files exist in the directory" do
      before do
        FileUtils.touch(File.join(temp_dir, "document.txt"))
        FileUtils.touch(File.join(temp_dir, "image.png"))
      end

      it "raises NoPDFsFoundError" do
        expect {
          Commands.rename(directory: temp_dir)
        }.to raise_error(NoPDFsFoundError, /no PDFs found/i)
      end
    end

    # @spec REN-SCAN-004
    describe "when all PDF files already conform to the naming pattern" do
      before do
        FileUtils.touch(File.join(temp_dir, "2026.01.15.WellsFargo.Statement.pdf"))
        FileUtils.touch(File.join(temp_dir, "2026.02.01.PGE.Bill.pdf"))
      end

      it "raises AllFilesConformingError" do
        expect {
          Commands.rename(directory: temp_dir)
        }.to raise_error(AllFilesConformingError, /all files already named/i)
      end
    end

    # @spec REN-PROC-003
    describe "when verbose mode is enabled" do
      before do
        FileUtils.touch(File.join(temp_dir, "document.pdf"))
        FileUtils.touch(File.join(temp_dir, "bank-statement.pdf"))
        FileUtils.touch(File.join(temp_dir, "2026.01.15.Already.Named.pdf"))
      end

      it "displays the list of files to be processed" do
        expect {
          Commands.rename(directory: temp_dir, verbose: true)
        }.to output(/document\.pdf.*bank-statement\.pdf|bank-statement\.pdf.*document\.pdf/m).to_stdout
      end

      it "does not display files that already conform" do
        expect {
          Commands.rename(directory: temp_dir, verbose: true)
        }.not_to output(/2026\.01\.15\.Already\.Named\.pdf/).to_stdout
      end
    end
  end
end
