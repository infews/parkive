# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe FieldExtractor do
    let(:sample_text) { "Statement Date: January 15, 2026\nWells Fargo Bank\nAccount: 1234" }
    let(:valid_hash) do
      {
        "date" => "2026.01.15",
        "credit_card" => "",
        "vendor" => "Wells Fargo",
        "account_number" => "1234",
        "invoice_number" => ""
      }
    end

    let(:mock_chat) { instance_double(RubyLLM::Chat) }
    let(:mock_response) { instance_double(RubyLLM::Message, content: valid_hash) }

    before do
      allow(FieldExtractor).to receive(:configure_ruby_llm)
      allow(RubyLLM).to receive(:chat).and_return(mock_chat)
      allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
      allow(mock_chat).to receive(:with_schema).and_return(mock_chat)
      allow(mock_chat).to receive(:ask).and_return(mock_response)
    end

    # @spec REN-LLM-001
    describe ".extract" do
      it "sends text to Ollama using the configured model" do
        FieldExtractor.extract(sample_text)

        expect(RubyLLM).to have_received(:chat).with(
          model: "qwen2.5:14b",
          provider: :ollama,
          assume_model_exists: true
        )
      end

      it "uses temperature 0" do
        FieldExtractor.extract(sample_text)

        expect(mock_chat).to have_received(:with_temperature).with(0)
      end

      it "uses the DocumentFieldsSchema" do
        FieldExtractor.extract(sample_text)

        expect(mock_chat).to have_received(:with_schema).with(DocumentFieldsSchema)
      end
    end

    # @spec REN-LLM-003
    describe "when Ollama returns a valid Hash" do
      it "returns all fields normalized" do
        result = FieldExtractor.extract(sample_text)

        expect(result).to be_a(Hash)
        expect(result["date"]).to eq("2026.01.15")
        expect(result["credit_card"]).to eq("")
        expect(result["vendor"]).to eq("Wells Fargo")
        expect(result["account_number"]).to eq("1234")
        expect(result["invoice_number"]).to eq("")
      end
    end

    # @spec REN-LLM-004
    describe "when Ollama returns a non-Hash response" do
      it "retries up to 3 times" do
        call_count = 0
        allow(mock_chat).to receive(:ask) do
          call_count += 1
          if call_count < 3
            instance_double(RubyLLM::Message, content: "not a hash")
          else
            mock_response
          end
        end

        result = FieldExtractor.extract(sample_text)

        expect(call_count).to eq(3)
        expect(result["date"]).to eq("2026.01.15")
      end
    end

    # @spec REN-LLM-005
    describe "when all retries fail" do
      it "returns nil for fallback to manual input" do
        bad_response = instance_double(RubyLLM::Message, content: "not a hash")
        allow(mock_chat).to receive(:ask).and_return(bad_response)

        result = FieldExtractor.extract(sample_text)

        expect(result).to be_nil
      end
    end

    # @spec REN-LLM-006
    describe "verbose mode" do
      it "displays raw Ollama response when verbose is enabled" do
        expect { FieldExtractor.extract(sample_text, verbose: true) }
          .to output(/Raw Ollama response/).to_stdout
      end
    end

    # @spec REN-LLM-007
    describe "verbose mode with retries" do
      it "displays retry attempts when verbose is enabled" do
        call_count = 0
        allow(mock_chat).to receive(:ask) do
          call_count += 1
          if call_count < 3
            instance_double(RubyLLM::Message, content: "not a hash")
          else
            mock_response
          end
        end

        expect { FieldExtractor.extract(sample_text, verbose: true) }
          .to output(/Retry attempt/).to_stdout
      end
    end

    describe "when response is a JSON string instead of Hash" do
      it "parses the string and returns the result" do
        json_string = '{"date": "2026.01.15", "credit_card": "", "vendor": "Wells Fargo", "account_number": "1234", "invoice_number": ""}'
        string_response = instance_double(RubyLLM::Message, content: json_string)
        allow(mock_chat).to receive(:ask).and_return(string_response)

        result = FieldExtractor.extract(sample_text)

        expect(result).to be_a(Hash)
        expect(result["date"]).to eq("2026.01.15")
      end
    end

    describe "when an exception occurs" do
      it "returns nil after max retries" do
        allow(mock_chat).to receive(:ask).and_raise(StandardError.new("connection refused"))

        result = FieldExtractor.extract(sample_text)

        expect(result).to be_nil
      end
    end
  end
end
