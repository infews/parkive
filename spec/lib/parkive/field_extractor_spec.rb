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
  end
end
