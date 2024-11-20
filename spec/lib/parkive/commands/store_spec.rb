# frozen_string_literal: true

require "prompts"
module Parkive
  RSpec.describe "Commands.store" do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }

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
          Commands.store(source_paths: Dir.glob(File.join(source_dir, "*")),
            archive_root: dest_dir,
            prompt: {})

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

      context "with a file that is already present in the archive destination" do
        before do
          FileUtils.copy(File.join(source_dir, file_1), File.join(dest_dir, "2004", "01.Jan"))
        end

        context "and the user skips" do
          it "only moves some of the files" do
            prompter = double("prompter")
            allow(prompter).to receive(:ask) { false }

            Commands.store(source_paths: Dir.glob(File.join(source_dir, "*")),
              archive_root: dest_dir,
              prompt: prompter)

            Dir.glob("/#{dest_dir}/*")

            # file_1 is in both locations
            expect(File.exist?(File.join(source_dir, file_1))).to eq(true)
            expect(File.exist?(File.join(dest_dir, "2004", "01.Jan", file_1))).to eq(true)

            expect(File.exist?(File.join(source_dir, file_2))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2004", "07.Jul", file_2))).to eq(true)

            expect(File.exist?(File.join(source_dir, file_3))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2013", "11.Nov", file_3))).to eq(true)
          end
        end

        context "and the user overwrites" do
          it "moves all of the files" do
            prompter = double("prompter")
            allow(prompter).to receive(:ask) { true }

            Commands.store(source_paths: Dir.glob(File.join(source_dir, "*")),
              archive_root: dest_dir,
              prompt: prompter)

            Dir.glob("/#{dest_dir}/*")

            # file_1 is moved b/c of prompt
            expect(File.exist?(File.join(source_dir, file_1))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2004", "01.Jan", file_1))).to eq(true)

            expect(File.exist?(File.join(source_dir, file_2))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2004", "07.Jul", file_2))).to eq(true)

            expect(File.exist?(File.join(source_dir, file_3))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2013", "11.Nov", file_3))).to eq(true)
          end
        end

        context "and the user forces" do
          it "moves all of the files" do
            Commands.store(source_paths: Dir.glob(File.join(source_dir, "*")),
              archive_root: dest_dir,
              prompt: {},
              force: true)

            Dir.glob("/#{dest_dir}/*")

            expect(File.exist?(File.join(source_dir, file_1))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2004", "01.Jan", file_1))).to eq(true)

            expect(File.exist?(File.join(source_dir, file_2))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2004", "07.Jul", file_2))).to eq(true)

            expect(File.exist?(File.join(source_dir, file_3))).to eq(false)
            expect(File.exist?(File.join(dest_dir, "2013", "11.Nov", file_3))).to eq(true)
          end
        end
      end
    end
  end
end
