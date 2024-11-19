# frozen_string_literal: true

require "spec_helper"
require "fileutils"

module Parkive
  RSpec.describe "Parkive::CLI#move" do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }

    context "when no destination is provided" do
      it "fails with a usage error" do
        expect do
          CLI.new.invoke(:move)
        end.to raise_error(Thor::InvocationError)
      end
    end

    context "when the destination does not exist" do
      it "fails with a useful error" do
        expect do
          CLI.new.invoke(:move, [File.join("foo")])
        end.to raise_error(NoDestinationDirectoryError)
      end
    end

    context "when there are no source files" do
      let(:source_dir) { File.join(temp_dir, "parkive", "source") }
      let(:dest_dir) { File.join(temp_dir, "parkive", "dest") }

      before do
        FileUtils.mkdir_p(source_dir)
        FileUtils.mkdir_p(dest_dir)
        Dir.chdir(source_dir) do
          FileUtils.touch "quux.txt"
        end
      end
      it "fails with a descriptive error" do
        expect do
          CLI.new.invoke(:move, [dest_dir], { source: source_dir })
        end.to raise_error(NoArchivableFilesFoundError)
      end
    end

    context "when the destination exists" do
      let(:source_dir) { File.join(temp_dir, "parkive", "source") }
      let(:dest_dir) { File.join(temp_dir, "parkive", "dest") }
      let(:file_1) { "2004.01.05.foo.pdf" }
      let(:file_2) { "2004.07.19.foo.pdf" }
      let(:file_3) { "2013.11.27.foo.pdf" }
      let(:file_4) { "quux.txt" }

      before do
        FileUtils.mkdir_p(source_dir)
        FileUtils.mkdir_p(File.join(dest_dir, "2004", "01.Jan"))
        FileUtils.mkdir_p(File.join(dest_dir, "2004", "07.Jul"))
        FileUtils.mkdir_p(File.join(dest_dir, "2013", "11.Nov"))
        Dir.chdir(source_dir) do
          FileUtils.touch [file_1, file_2, file_3, file_4]
        end
      end

      context "and no file is already present in the destination" do
        it "moves archivable files to the destination" do
          CLI.new.invoke(:move, [dest_dir], { source: source_dir })

          Dir.glob("/#{dest_dir}/*")

          expect(File.exist?(File.join(source_dir, file_1))).to eq(false)
          expect(File.exist?(File.join(dest_dir, "2004", "01.Jan", file_1))).to eq(true)

          expect(File.exist?(File.join(source_dir, file_2))).to eq(false)
          expect(File.exist?(File.join(dest_dir, "2004", "07.Jul", file_2))).to eq(true)

          expect(File.exist?(File.join(source_dir, file_3))).to eq(false)
          expect(File.exist?(File.join(dest_dir, "2013", "11.Nov", file_3))).to eq(true)
        end

        it "does mot move non matching files to the destination" do
          expect(File.exist?(File.join(source_dir, file_4))).to eq(true)
        end
      end
    end
  end
end
