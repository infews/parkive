module Parkive::Commands
  RSpec.describe MakeDirectories do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }
    let(:this_year) { Time.now.year.to_s }

    it "builds commands" do
      commands = MakeDirectories.new(temp_dir, this_year).build

      dirs = Parkive::MONTH_DIRNAMES.values
      dirs << "#{this_year}.Media"
      dirs << "#{this_year}.Tax"

      dirs.each do |dir|
        expect(commands).to include("mkdir -p #{File.join(temp_dir, this_year, dir)}")
      end
    end
  end
end
