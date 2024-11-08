module Parkive::Commands
  RSpec.describe Factory do
    describe ".forMakeDirectories" do
      context "when gum is not installed" do
        it "returns a MakeDirectories" do
          klass = Factory.forMakeDirectories(false)
          expect(klass).to eq(MakeDirectories)
        end
      end

      context "when gum is  installed" do
        it "returns a MakeDirectories" do
          klass = Factory.forMakeDirectories(true)
          expect(klass).to eq(GumMakeDirectories)
        end
      end
    end
  end
end
