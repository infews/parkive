module Parkive::Commands
  RSpec.describe GumMakeDirectories do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }
    let(:this_year) { Time.now.year.to_s }

    it "builds commands" do
      commands = GumMakeDirectories.new(temp_dir, this_year).commands

      expect(commands.length).to eq(2)
      expect(commands.first).to include("gum style")
      expect(commands.first).to include("Creating archive directories in #{File.join(temp_dir, this_year)}")
      expect(commands[1]).to include("echo \"#{File.join(temp_dir, this_year, "01.Jan")} ")
      expect(commands[1]).to include("| xargs mkdir -p")
    end
  end
end
