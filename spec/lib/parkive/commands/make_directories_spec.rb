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
      command = MakeDirectories.new(temp_dir, this_year)
      commands = command.build

      expect(commands.length).to eq(1)
      expect(commands.first).to match(/^echo /)
      expect(commands.first).to match(/| xargs mkdir -p$/)

      command.dirs.each do |path|
        expect(commands.first).to include(path)
      end
    end
  end
end
