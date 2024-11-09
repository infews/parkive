# frozen_string_literal: true

require "spec_helper"
module Parkive
  RSpec.describe "Parkive::CLI#move" do
    around :each do |example|
      Dir.mktmpdir do |dir|
        @temp_dir = dir
        example.run
      end
    end
    let(:temp_dir) { @temp_dir }
    let(:this_year) { Time.now.year.to_s }

    context "when no destination is provided" do
      it "fails with a usage error" do
        expect do
          CLI.new.invoke(:move)
        end.to raise_error(Thor::InvocationError)
      end
    end

    context "when the destination does not exist" do
      it "fails with a useful error" do
        expect do
          CLI.new.invoke(:move, ["#{temp_dir}/foo"])
        end.to raise_error(NoDestinationDirectoryError)
      end
    end

    context "when the destination exists" do
      it "moves matching files to the destination"
      it "does mot move non matching files to the destination"
    end

    # how to handle files that are already present?
    # use -i for command b/c don't overwrite without permission

  end
end
