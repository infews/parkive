# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe FieldExtractor do
    # @spec REN-LLM-001
    describe ".extract" do
      let(:sample_text) { "Statement Date: January 15, 2026\nWells Fargo Bank\nAccount: 1234" }

      it "sends text to Ollama using the llama3.1:8b model" do
        chat_double = instance_double("RubyLLM::Chat")
        allow(RubyLLM).to receive(:chat).and_return(chat_double)
        allow(chat_double).to receive(:ask).and_return('{"date": "2026.01.15", "vendor": "Wells Fargo", "credit_card": "", "account_number": "1234", "invoice_number": "", "type": "Statement", "other": ""}')

        FieldExtractor.extract(sample_text)

        expect(RubyLLM).to have_received(:chat).with(hash_including(model: "llama3.1:8b"))
      end
    end

    # @spec REN-LLM-002
    describe ".build_prompt" do
      it "requests JSON output with all required fields" do
        prompt = FieldExtractor.build_prompt("sample text")

        expect(prompt).to include("date")
        expect(prompt).to include("credit_card")
        expect(prompt).to include("vendor")
        expect(prompt).to include("account_number")
        expect(prompt).to include("invoice_number")
        expect(prompt).to include("type")
        expect(prompt).to include("other")
        expect(prompt).to include("JSON")
      end
    end

    # @spec REN-LLM-003
    describe "when Ollama returns valid JSON" do
      let(:sample_text) { "Statement Date: January 15, 2026\nWells Fargo Bank\nAccount: 1234" }
      let(:valid_json) { '{"date": "2026.01.15", "credit_card": "Visa", "vendor": "Wells Fargo", "account_number": "1234", "invoice_number": "INV-001", "type": "Statement", "other": "Monthly"}' }

      it "parses all fields from the response" do
        chat_double = instance_double("RubyLLM::Chat")
        allow(RubyLLM).to receive(:chat).and_return(chat_double)
        allow(chat_double).to receive(:ask).and_return(valid_json)

        result = FieldExtractor.extract(sample_text)

        expect(result).to be_a(Hash)
        expect(result["date"]).to eq("2026.01.15")
        expect(result["credit_card"]).to eq("Visa")
        expect(result["vendor"]).to eq("Wells Fargo")
        expect(result["account_number"]).to eq("1234")
        expect(result["invoice_number"]).to eq("INV-001")
        expect(result["type"]).to eq("Statement")
        expect(result["other"]).to eq("Monthly")
      end
    end
  end
end
