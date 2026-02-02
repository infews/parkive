# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe TextExtractor do
    # @spec REN-TEXT-001
    describe ".extract" do
      context "when processing a valid PDF with text" do
        let(:pdf_path) { File.expand_path("../../fixtures/sample-with-text.pdf", __dir__) }

        it "extracts text content using Poppler" do
          result = TextExtractor.extract(pdf_path)

          expect(result).to be_a(String)
          expect(result).not_to be_empty
          expect(result).to include("Sample Document")
        end
      end
    end
  end
end
