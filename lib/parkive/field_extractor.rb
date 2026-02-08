# frozen_string_literal: true

require "ruby_llm"
require_relative "document_fields_schema"

# @spec REN-LLM-001, REN-LLM-002, REN-LLM-003
module Parkive
  class FieldExtractor
    MODEL = "qwen2.5:14b"
    EXAMPLES_DIR = File.join(__dir__, "examples")
    EXAMPLES = {
      amex: {
        text: File.read(File.join(EXAMPLES_DIR, "amex.txt")),
        output: {date: "2025.02.17", vendor: "Delta SkyMiles", credit_card: "American Express", account_number: "6-12345", invoice_number: ""}
      },
      apple: {
        text: File.read(File.join(EXAMPLES_DIR, "apple.txt")),
        output: {date: "2025.02.28", vendor: "Goldman", credit_card: "Apple Card", account_number: "", invoice_number: ""}
      },
      etrade: {
        text: File.read(File.join(EXAMPLES_DIR, "etrade.txt")),
        output: {date: "2025.02.28", vendor: "E*Trade", credit_card: "", account_number: "520-291109", invoice_number: ""}
      },
      etrade_2: {
        text: File.read(File.join(EXAMPLES_DIR, "etrade_2.txt")),
        output: {date: "2025.02.28", vendor: "E*Trade", credit_card: "", account_number: "520-852519", invoice_number: ""}
      },
      sal: {
        text: File.read(File.join(EXAMPLES_DIR, "sal.txt")),
        output: {date: "2025.02.27", vendor: "Sals Landscaping", credit_card: "", account_number: "", invoice_number: "12950"}
      }
    }.freeze

    MAX_RETRIES = 3

    def self.configure_ruby_llm
      return if @configured

      RubyLLM.configure do |config|
        config.ollama_api_base = "http://localhost:11434/v1"
      end
      @configured = true
    end

    # @spec REN-LLM-004, REN-LLM-005, REN-LLM-006, REN-LLM-007
    def self.extract(text, verbose: false)
      configure_ruby_llm

      attempts = 0

      loop do
        attempts += 1

        chat = RubyLLM.chat(model: MODEL, provider: :ollama, assume_model_exists: true)
          .with_temperature(0)
          .with_schema(DocumentFieldsSchema)

        response = chat.ask(build_prompt(text))

        # @spec REN-LLM-006
        puts "Raw Ollama response: #{response.content}" if verbose

        result = response.content
        return normalize(result) if result.is_a?(Hash)

        # If content came back as a string, try to parse it
        parsed = parse_string_response(result.to_s)
        return normalize(parsed) unless parsed.nil?

        # @spec REN-LLM-007
        puts "Retry attempt #{attempts} failed: response not a valid Hash" if verbose && attempts < MAX_RETRIES

        # @spec REN-LLM-005
        return nil if attempts >= MAX_RETRIES
      rescue => e
        puts "Attempt #{attempts} error: #{e.message}" if verbose
        return nil if attempts >= MAX_RETRIES
      end
    end

    def self.build_prompt(text)
      parts = []
      parts << "Extract the key fields from this financial document."
      parts << ""
      parts << "Date format: Convert all dates to YYYY.MM.DD format."
      parts << '- "02/17/25" becomes "2025.02.17"'
      parts << '- "February 17, 2025" becomes "2025.02.17"'
      parts << "- Use the statement closing date, not today's date."
      parts << ""
      parts << 'Use empty string "" for any field not found in the document.'
      parts << ""
      parts << "For credit card statements: credit_card is the payment NETWORK (American Express, Visa, Mastercard),"
      parts << "not the card product name. The card product name (e.g. Delta SkyMiles) goes in vendor."
      parts << ""
      parts << "Examples:"

      EXAMPLES.each do |_name, example|
        parts << ""
        parts << "Document: #{example[:text][0, 200]}..."
        parts << "Output: #{example[:output].to_json}"
      end

      parts << ""
      parts << "Document to extract from:"
      parts << "---"
      parts << text
      parts << "---"

      parts.join("\n")
    end

    def self.normalize(hash)
      {
        "date" => hash["date"].to_s,
        "credit_card" => hash["credit_card"].to_s,
        "vendor" => hash["vendor"].to_s,
        "account_number" => hash["account_number"].to_s,
        "invoice_number" => hash["invoice_number"].to_s
      }
    end

    def self.parse_string_response(content)
      cleaned = content.strip.gsub(/```json\s*/, "").gsub(/```\s*/, "")
      if (match = cleaned.match(/\{[^{}]*\}/))
        JSON.parse(match[0])
      else
        JSON.parse(cleaned)
      end
    rescue JSON::ParserError
      nil
    end

    private_class_method :build_prompt, :normalize, :parse_string_response
  end
end
