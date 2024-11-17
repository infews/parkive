# frozen_string_literal: true

module Parkive
  RSpec.describe Archiver do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end

    let(:temp_dir) { @temp_dir }
    let(:archive_root) { File.join(temp_dir, "archive_root") }
    let(:move_me) { ArchivablePathname.new(File.join(temp_dir, "move_me")) }
    let(:move_me_too) { ArchivablePathname.new(File.join(temp_dir, "move_me_too")) }
    let(:stay_put) { ArchivablePathname.new(File.join(temp_dir, "stay_put")) }
    let(:archiver) { Archiver.new([move_me, move_me_too, stay_put], archive_root) }

    before do
      FileUtils.mkdir(archive_root)
      FileUtils.touch([move_me, move_me_too, stay_put])
    end

    describe "#move_to" do
      it "moves only the files that are truthy" do
        archiver.move_to { |path| path == move_me || path == move_me_too }

        expect(File.exist?(move_me)).to eq(false)
        expect(File.exist?(File.join(archive_root, move_me.basename))).to eq(true)
        expect(File.exist?(move_me_too)).to eq(false)
        expect(File.exist?(File.join(archive_root, move_me_too.basename))).to eq(true)
        expect(File.exist?(stay_put)).to eq(true)
        expect(File.exist?(File.join(archive_root, stay_put.basename))).to eq(false)
      end

      it "returns the files that were not moved" do
        remaining = archiver.move_to { |path| path == move_me || path == move_me_too }

        expect(remaining.first).to eq(stay_put)
      end
    end
  end
end
