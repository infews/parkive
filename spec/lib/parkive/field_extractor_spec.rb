# frozen_string_literal: true

require "spec_helper"

module Parkive
  RSpec.describe FieldExtractor do
    # @spec REN-LLM-001
    describe ".extract" do
      let(:sample_text) { "Statement Date: January 15, 2026\nWells Fargo Bank\nAccount: 1234" }
      let(:valid_json) { '{"date": "2026.01.15", "vendor": "Wells Fargo", "credit_card": "", "account_number": "1234", "invoice_number": ""}' }

      it "sends text to Ollama using the configured model" do
        response_body = { "response" => valid_json, "done" => true }.to_json
        http_response = instance_double(Net::HTTPResponse, body: response_body)
        http = instance_double(Net::HTTP)
        request_body = nil

        allow(Net::HTTP).to receive(:new).with("localhost", 11434).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request) do |req|
          request_body = JSON.parse(req.body)
          http_response
        end

        FieldExtractor.extract(sample_text)

        expect(request_body["model"]).to eq("qwen2.5:14b")
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
        expect(prompt).to include("JSON")
      end
    end

    # @spec REN-LLM-003
    describe "when Ollama returns valid JSON" do
      let(:sample_text) { "Statement Date: January 15, 2026\nWells Fargo Bank\nAccount: 1234" }
      let(:valid_json) { '{"date": "2026.01.15", "credit_card": "Visa", "vendor": "Wells Fargo", "account_number": "1234", "invoice_number": "INV-001"}' }

      it "parses all fields from the response" do
        response_body = { "response" => valid_json, "done" => true }.to_json
        http_response = instance_double(Net::HTTPResponse, body: response_body)
        http = instance_double(Net::HTTP)

        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(http_response)

        result = FieldExtractor.extract(sample_text)

        expect(result).to be_a(Hash)
        expect(result["date"]).to eq("2026.01.15")
        expect(result["credit_card"]).to eq("Visa")
        expect(result["vendor"]).to eq("Wells Fargo")
        expect(result["account_number"]).to eq("1234")
        expect(result["invoice_number"]).to eq("INV-001")
      end
    end

    # @spec REN-LLM-004
    describe "when Ollama returns invalid JSON" do
      let(:sample_text) { "Some document text" }
      let(:invalid_json) { "This is not valid JSON" }
      let(:valid_json) { '{"date": "2026.01.15", "credit_card": "", "vendor": "", "account_number": "", "invoice_number": ""}' }

      it "retries up to 3 times" do
        http = instance_double(Net::HTTP)
        call_count = 0

        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request) do
          call_count += 1
          response_content = call_count < 3 ? invalid_json : valid_json
          response_body = { "response" => response_content, "done" => true }.to_json
          instance_double(Net::HTTPResponse, body: response_body)
        end

        result = FieldExtractor.extract(sample_text)

        expect(call_count).to eq(3)
        expect(result["date"]).to eq("2026.01.15")
      end
    end

    # @spec REN-LLM-005
    describe "when all retries fail" do
      let(:sample_text) { "Some document text" }
      let(:invalid_json) { "This is not valid JSON" }

      it "returns nil for fallback to manual input" do
        http = instance_double(Net::HTTP)

        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request) do
          response_body = { "response" => invalid_json, "done" => true }.to_json
          instance_double(Net::HTTPResponse, body: response_body)
        end

        result = FieldExtractor.extract(sample_text)

        expect(result).to be_nil
      end
    end

    # @spec REN-LLM-006
    describe "verbose mode" do
      let(:sample_text) { "Statement Date: January 15, 2026" }
      let(:valid_json) { '{"date": "2026.01.15", "credit_card": "", "vendor": "", "account_number": "", "invoice_number": ""}' }

      it "displays raw Ollama response when verbose is enabled" do
        http = instance_double(Net::HTTP)
        response_body = { "response" => valid_json, "done" => true }.to_json
        http_response = instance_double(Net::HTTPResponse, body: response_body)

        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request).and_return(http_response)

        expect { FieldExtractor.extract(sample_text, verbose: true) }.to output(/Raw Ollama response/).to_stdout
      end
    end

    # @spec REN-LLM-007
    describe "verbose mode with retries" do
      let(:sample_text) { "Some document text" }
      let(:invalid_json) { "This is not valid JSON" }
      let(:valid_json) { '{"date": "2026.01.15", "credit_card": "", "vendor": "", "account_number": "", "invoice_number": ""}' }

      it "displays retry attempts when verbose is enabled" do
        http = instance_double(Net::HTTP)
        call_count = 0

        allow(Net::HTTP).to receive(:new).and_return(http)
        allow(http).to receive(:read_timeout=)
        allow(http).to receive(:request) do
          call_count += 1
          response_content = call_count < 3 ? invalid_json : valid_json
          response_body = { "response" => response_content, "done" => true }.to_json
          instance_double(Net::HTTPResponse, body: response_body)
        end

        expect { FieldExtractor.extract(sample_text, verbose: true) }.to output(/Retry attempt/).to_stdout
      end
    end
  end
end
