# frozen_string_literal: true

module Parkive
  RSpec.describe ArchivablePathname do
    describe ".from" do
      it "returns an array of ArchivableFiles only for filenames that match" do
        files = ["/a/b/2024.01.31.foo.pdf",
          "/a/b/1997.11.03.bar.txt",
          "/foo/b/2000.05.17.baz.map",
          "/s/d/2000.19.43.corge.jpg",
          "quux.txt"]

        archivables = ArchivablePathname.from(files)

        expect(archivables.size).to eq(3)
        expect(archivables.first).to be_a(ArchivablePathname)
      end
    end

    context "instance methods" do
      let(:archivable) { ArchivablePathname.new(filename) }

      context "when it has an archive-ready name" do
        let(:filename) { "/a/b/2004.12.17.foo.pdf" }

        describe "#is_archivable?" do
          it "returns true" do
            expect(archivable.is_archivable?).to eq(true)
          end
        end

        describe "#archive_path" do
          it "returns the archive path" do
            expect(archivable.archive_path).to eq(File.join("2004", "12.Dec"))
          end
        end

        context "when it does not have an archive-ready name" do
          let(:filename) { "quux.txt" }

          describe "#is_archivable?" do
            it "returns true" do
              expect(archivable.is_archivable?).to eq(false)
            end
          end

          describe "#archive_path" do
            it "returns the archive path" do
              expect(archivable.archive_path).to eq("")
            end
          end
        end
      end
    end
  end
end
