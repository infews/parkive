# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe "Parkive::CLI#rename" do
    # @spec REN-CLI-001
    context "when no directory is provided" do
      it "fails with a usage error" do
        expect do
          CLI.new.invoke(:rename)
        end.to raise_error(Thor::InvocationError)
      end
    end

    # @spec REN-CLI-002
    context "when the directory does not exist" do
      it "fails with a useful error" do
        expect do
          CLI.new.invoke(:rename, ["nonexistent_directory"])
        end.to raise_error(NoSourceDirectoryError)
      end
    end
  end
end
