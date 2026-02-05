# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

# @spec REN-LLM-001, REN-LLM-002, REN-LLM-003
module Parkive
  class FieldExtractor
    OLLAMA_URL = "http://localhost:11434/api/generate"
    MODEL = "qwen2.5:14b"
    EXAMPLES_DIR = File.join(__dir__, "examples")
    EXAMPLES = {
      amex: {
        example: "#{File.read(File.join(EXAMPLES_DIR, "amex.txt"))}",
        output: { date: "2025.02.17",
                  vendor: "Delta SkyMiles",
                  credit_card: "American Express",
                  account_number: "6-12345",
                  invoice_number: "" }.to_json
      },
      apple: {
        example: "#{File.read(File.join(EXAMPLES_DIR, "apple.txt"))}",
        output: { date: "2025.02.28",
                  vendor: "Goldman",
                  credit_card: "Apple Card",
                  account_number: "",
                  invoice_number: "" }.to_json
      },
      etrade: {
        example: "#{File.read(File.join(EXAMPLES_DIR, "etrade.txt"))}",
        output: { date: "2025.02.28",
                  vendor: "E*Trade",
                  credit_card: "",
                  account_number: "520-291109",
                  invoice_number: "" }.to_json,
      },
      etrade_2: {
        example: "#{File.read(File.join(EXAMPLES_DIR, "etrade_2.txt"))}",
        output: { date: "2025.02.28",
                  vendor: "E*Trade",
                  credit_card: "",
                  account_number: "520-852519",
                  invoice_number: "" }.to_json,
      },
      sal: {
        example: "#{File.read(File.join(EXAMPLES_DIR, "sal.txt"))}",
        output: { date: "2025.02.27",
                  vendor: "Sals Landscaping",
                  credit_card: "",
                  account_number: "",
                  invoice_number: "12950" }.to_json
      }
    }

    MAX_RETRIES = 3

    # @spec REN-LLM-004, REN-LLM-005, REN-LLM-006, REN-LLM-007
    def self.extract(text, verbose: false)
      attempts = 0

      loop do
        attempts += 1
        response = send_prompt(text)

        # @spec REN-LLM-006
        puts "Raw Ollama response: #{response}" if verbose

        result = parse_response(response)

        # If parsing succeeded (no error key), return the result
        return result unless result.key?(:error) || result.key?("error")

        # @spec REN-LLM-007
        puts "Retry attempt #{attempts} failed: invalid JSON" if verbose && attempts < MAX_RETRIES

        # @spec REN-LLM-005 - If we've exhausted retries, return nil for fallback to manual input
        return nil if attempts >= MAX_RETRIES
      end
    end

    def self.send_prompt(text)
      uri = URI(OLLAMA_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 120 # LLM responses can be slow

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        model: MODEL,
        prompt: build_prompt(text),
        stream: false,
        options: {
          temperature: 0,
          num_ctx: 16384  # 16K tokens
        }
      }.to_json

      response = http.request(request)
      JSON.parse(response.body)["response"]
    end

    def self.parse_response(content)
      # Strip any whitespace or markdown fences
      cleaned = content.strip.gsub(/```json\s*/, "").gsub(/```\s*/, "")

      # Extract JSON object if surrounded by other text
      if (match = cleaned.match(/\{[^{}]*\}/))
        JSON.parse(match[0])
      else
        JSON.parse(cleaned)
      end
    rescue JSON::ParserError => e
      { error: "Failed to parse response", raw: content, message: e.message }
    end

    def self.build_prompt(text)
      examples = EXAMPLES.each.map do |vendor, output|
        "Document: #{vendor}\nOutput: #{output}"
      end.join("\n\n")

      <<~PROMPT
        You are a document field extractor. Extract fields from the document below and return JSON.

        IMPORTANT DATE FORMAT RULE:
        The date field MUST use format YYYY.MM.DD (4-digit year DOT 2-digit month DOT 2-digit day).
        If document shows "02/17/25" or "February 17, 2025", or "February 1-17, 2025", convert to "2025.02.17".
        If document shows "Closing Date 02/17/25", the year is 2025, so output "2025.02.17".

        Fields to extract:
        - date: Statement/closing date in YYYY.MM.DD format (REQUIRED)
        - credit_card: Card type like "Visa", "American Express" (if applicable)
        - vendor: Company name like "Fidelity", "E*Trade", "Delta Skymiles"
        - account_number: Account number, whitespace removed, if present
        - invoice_number: Invoice number, whitespace removed, if present

        Use empty string "" for fields not found. Return ONLY valid JSON, no other text.

        Examples:
        #{examples}

        Document to Extract from:
        ---
        #{text}
        ---
      PROMPT
    end
  end
end
