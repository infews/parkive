# frozen_string_literal: true

require "spec_helper"
require "net/http"

module Parkive
  # These tests hit the real Ollama API and require:
  # - Ollama installed
  # - llama3.1:8b model pulled
  #
  # The test suite will start/stop Ollama automatically.
  #
  # Run with: bundle exec rspec spec/lib/parkive/live_examples_field_extractor_spec.rb
  # Skip in CI by using: bundle exec rspec --tag ~live
  RSpec.describe FieldExtractor, :live do
    let(:fixtures_path) { File.expand_path("../../fixtures/live", __dir__) }

    # Strict date pattern: YYYY.MM.DD format only
    let(:strict_date_pattern) { /^\d{4}\.\d{2}\.\d{2}$/ }

    # Track whether we started Ollama so we only stop it if we started it
    @ollama_started_by_tests = false

    class << self
      attr_accessor :ollama_started_by_tests
    end

    def self.ollama_running?
      uri = URI("http://localhost:11434/api/tags")
      response = Net::HTTP.get_response(uri)
      response.is_a?(Net::HTTPSuccess)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET
      false
    end

    def self.wait_for_ollama(timeout: 30)
      start_time = Time.now
      until ollama_running?
        if Time.now - start_time > timeout
          raise "Ollama failed to start within #{timeout} seconds"
        end
        sleep 0.5
      end
    end

    before(:context) do
      unless self.class.ollama_running?
        puts "\nStarting Ollama server..."
        @ollama_pid = spawn("ollama serve", out: "/dev/null", err: "/dev/null")
        Process.detach(@ollama_pid)
        self.class.ollama_started_by_tests = true
        self.class.wait_for_ollama
        puts "Ollama server started (pid: #{@ollama_pid})"
      end
    end

    after(:context) do
      if self.class.ollama_started_by_tests
        puts "\nStopping Ollama server..."
        system("pkill -f 'ollama serve'", out: "/dev/null", err: "/dev/null")
        self.class.ollama_started_by_tests = false
        puts "Ollama server stopped"
      end
    end

    describe "with Amex Delta statement" do
      let(:sample_text) { File.read(File.join(fixtures_path, "amex.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to match(strict_date_pattern), "Expected date in YYYY.MM.DD format, got: #{result["date"]}"
        expect(result["credit_card"]).to eq("American Express")
        expect(result["vendor"]).to match(/Delta/)
        expect(result["account_number"]).to eq("6-12345")
        expect(result["invoice_number"]).to be_empty
      end
    end

    describe "with E*Trade statement" do
      let(:sample_text) { File.read(File.join(fixtures_path, "etrade.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to match(strict_date_pattern), "Expected date in YYYY.MM.DD format, got: #{result["date"]}"
        expect(result["credit_card"]).to be_empty
        expect(result["vendor"]).to eq("E*Trade").or match(/Morgan/)
        expect(result["account_number"]).to eq("520-291109")
        expect(result["invoice_number"]).to be_empty
      end
    end

    describe "with another E*Trade statement" do
      let(:sample_text) { File.read(File.join(fixtures_path, "etrade_2.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to match(strict_date_pattern), "Expected date in YYYY.MM.DD format, got: #{result["date"]}"
        expect(result["credit_card"]).to be_empty
        expect(result["vendor"]).to eq("E*Trade").or match(/Morgan/)
        expect(result["account_number"]).to eq("520-852519")
        expect(result["invoice_number"]).to be_empty
      end
    end

    describe "with Apple Card statement" do
      let(:sample_text) { File.read(File.join(fixtures_path, "apple.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to match(strict_date_pattern), "Expected date in YYYY.MM.DD format, got: #{result["date"]}"
        expect(result["credit_card"]).to eq("Apple Card")
        expect(result["vendor"]).to match(/Goldman/)
        expect(result["account_number"]).to be_empty
        expect(result["invoice_number"]).to be_empty
      end
    end

    describe "from Sal's invoice" do
      let(:sample_text) { File.read(File.join(fixtures_path, "sal.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to match(strict_date_pattern), "Expected date in YYYY.MM.DD format, got: #{result["date"]}"
        expect(result["credit_card"]).to be_empty
        expect(result["vendor"]).to eq("Sals Landscaping")
        expect(result["account_number"]).to be_empty
        expect(result["invoice_number"]).to eq("12950")
      end
    end

    describe "from HealthEquity" do
      let(:sample_text) { File.read(File.join(fixtures_path, "hequity.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to eq("2025.02.28")
        expect(result["credit_card"]).to be_empty
        expect(result["vendor"]).to eq("HealthEquity")
        expect(result["account_number"]).to eq("20581892")
        expect(result["invoice_number"]).to eq("")
      end
    end

    describe "from Fidelity" do
      let(:sample_text) { File.read(File.join(fixtures_path, "fidelity.txt")) }

      it "extracts fields correctly" do
        result = FieldExtractor.extract(sample_text)
        pp result if ENV["DEBUG"]

        expect(result).to be_a(Hash)
        expect(result["date"]).to eq("2025.02.28")
        expect(result["credit_card"]).to be_empty
        expect(result["vendor"]).to eq("Fidelity")
        expect(result["account_number"]).to eq("Z28-354564")
        expect(result["invoice_number"]).to eq("")
      end
    end
  end
end
