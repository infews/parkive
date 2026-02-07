# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe NameSuggestor do
    # @spec REN-NAME-001
    describe "field ordering" do
      it "builds filename from fields in order: date, credit_card, vendor, account_number, invoice_number" do
        fields = {
          "date" => "2026.01.31",
          "credit_card" => "Visa",
          "vendor" => "Costco",
          "account_number" => "9876",
          "invoice_number" => ""
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("2026.01.31.Visa.Costco.9876.pdf")
      end
    end

    # @spec REN-NAME-002
    describe "empty field handling" do
      it "omits empty fields from the filename" do
        fields = {
          "date" => "2026.01.31",
          "credit_card" => "",
          "vendor" => "Fidelity",
          "account_number" => "12345",
          "invoice_number" => ""
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("2026.01.31.Fidelity.12345.pdf")
      end
    end

    # @spec REN-NAME-003
    describe "whitespace handling" do
      it "replaces whitespace with dots in field values" do
        fields = {
          "date" => "2026.03.01",
          "vendor" => "City of Burlingame",
          "invoice_number" => "INV 001"
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("2026.03.01.City.of.Burlingame.INV.001.pdf")
      end
    end

    # @spec REN-NAME-004
    describe "filesystem safety" do
      it "removes unsafe characters: / \\ : * ? \" < > |" do
        fields = {
          "date" => "2026.01.15",
          "vendor" => "Test/Company\\Name:With*Bad?Chars\"<>|"
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("2026.01.15.TestCompanyNameWithBadChars.pdf")
      end
    end

    # @spec REN-NAME-005
    describe "dot collapsing" do
      it "collapses multiple consecutive dots into a single dot" do
        fields = {
          "date" => "2026.01.15",
          "vendor" => "Test / Company"
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("2026.01.15.Test.Company.pdf")
      end
    end

    # @spec REN-NAME-006
    describe "missing date handling" do
      it "uses UNKNOWN when date is empty" do
        fields = {
          "date" => "",
          "vendor" => "Unknown Corp"
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("UNKNOWN.Unknown.Corp.pdf")
      end

      it "uses UNKNOWN when date is missing" do
        fields = {
          "vendor" => "Unknown Corp"
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to eq("UNKNOWN.Unknown.Corp.pdf")
      end
    end

    # @spec REN-NAME-007
    describe ".pdf extension" do
      it "appends .pdf to the generated filename" do
        fields = {
          "date" => "2026.01.31",
          "vendor" => "Fidelity"
        }

        result = NameSuggestor.suggest(fields)

        expect(result).to end_with(".pdf")
      end
    end
  end
end
