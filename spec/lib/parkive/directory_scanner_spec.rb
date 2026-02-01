# frozen_string_literal: true

require "spec_helper"
require "fileutils"

module Parkive
  RSpec.describe DirectoryScanner do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }

    # @spec REN-SCAN-001
    describe ".scan" do
      context "when directory contains .pdf and .PDF files" do
        before do
          FileUtils.touch(File.join(temp_dir, "document.pdf"))
          FileUtils.touch(File.join(temp_dir, "REPORT.PDF"))
          FileUtils.touch(File.join(temp_dir, "notes.txt"))
        end

        it "finds both .pdf and .PDF files" do
          results = DirectoryScanner.scan(temp_dir)
          basenames = results.map { |f| File.basename(f) }

          expect(basenames).to include("document.pdf")
          expect(basenames).to include("REPORT.PDF")
          expect(basenames).not_to include("notes.txt")
        end
      end

      # @spec REN-SCAN-002
      context "when directory contains files that already match the archivable pattern" do
        before do
          FileUtils.touch(File.join(temp_dir, "2026.01.15.WellsFargo.Statement.pdf"))
          FileUtils.touch(File.join(temp_dir, "2026.02.01.PGE.Bill.PDF"))
          FileUtils.touch(File.join(temp_dir, "document.pdf"))
          FileUtils.touch(File.join(temp_dir, "bank-statement.pdf"))
        end

        it "filters out files that already conform to the pattern" do
          results = DirectoryScanner.scan(temp_dir)
          basenames = results.map { |f| File.basename(f) }

          expect(basenames).to include("document.pdf")
          expect(basenames).to include("bank-statement.pdf")
          expect(basenames).not_to include("2026.01.15.WellsFargo.Statement.pdf")
          expect(basenames).not_to include("2026.02.01.PGE.Bill.PDF")
        end
      end
    end
  end
end
