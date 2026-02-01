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
  end
end
