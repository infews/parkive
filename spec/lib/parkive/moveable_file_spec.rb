# frozen_string_literal: true

module Parkive
  RSpec.describe MoveableFile do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end

    let(:temp_dir) { @temp_dir }
    let(:path) { "#{temp_dir}/test.txt" }
    let(:mfile) { MoveableFile.new(path) }

    describe "#path" do
      it "should be an attribute" do
        expect(mfile.path).to eq(path)
      end
    end

    context "existence" do
      describe "#exist?" do
        it "should reflect the path on the filesystem" do
          expect(mfile.exist?).to eq(false)
          FileUtils.touch(path)
          expect(mfile.exist?).to eq(true)
        end
      end
    end

    context "wanting to move" do
      describe "#move" do
        it "is an attribute" do
          expect(mfile.move).to eq(false)
          mfile.move = true
          expect(mfile.move).to eq(true)
        end
      end

      describe "#move?" do
        it "reflects the state of the attribute" do
          expect(mfile.move?).to eq(false)
          mfile.move = true
          expect(mfile.move?).to eq(true)
        end
      end
    end
  end
end
