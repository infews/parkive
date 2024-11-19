# module Parkive::Commands
#   # RSpec.describe MakeDirectories do
#   #   around :each do |example|
#   #     Dir.mktmpdir do |dir|
#   #       @temp_dir = dir
#   #       example.run
#   #     end
#   #   end
#   #   let(:temp_dir) { @temp_dir }
#   #   let(:this_year) { Time.now.year.to_s }
#   #
#     # it "builds commands" do
#     #   cmd = MakeDirectories.new(temp_dir, this_year)
#     #   commands = cmd.commands
#     #
#     #   expect(commands.length).to eq(2)
#     #   expect(commands.first).to match("Creating archive directories")
#     #
#     #   expect(commands.last).to match(/^echo /)
#     #   expect(commands.last).to match(/| xargs mkdir -p$/)
#     #
#     #   cmd.dirs.each do |path|
#     #     expect(commands.last).to include(path)
#     #   end
#     # end
#   end
# end
