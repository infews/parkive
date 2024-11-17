# frozen_string_literal: true

module Parkive
  RSpec.describe MoveableFile do

    let(:mfile) { MoveableFile.new }

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
