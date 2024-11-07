# frozen_string_literal: true

module Parkive
  RSpec.describe "Parkive::CLI#help" do
    it "lists all commands" do
      expect {
        CLI.new.invoke(:help)
      }.to output(
        a_string_including("make_directories DST YEAR")
      ).to_stdout
    end
  end
end
