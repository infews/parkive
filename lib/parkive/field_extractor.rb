# frozen_string_literal: true

require "ruby_llm"

# @spec REN-LLM-001
module Parkive
  class FieldExtractor
    MODEL = "llama3.1:8b"

    def self.extract(text)
      chat = RubyLLM.chat(model: MODEL)
      response = chat.ask(build_prompt(text))
      JSON.parse(response)
    end

    def self.build_prompt(text)
      <<~PROMPT
        Extract the following from this document text. Return ALL fields, using empty string "" for any field not found.

        Required:
        - date: The statement/document date in YYYY.MM.DD format

        Optional:
        - credit_card: Card type if this is a credit card statement (e.g., "Visa", "Master Card", "American Express")
        - vendor: The bank or provider name (e.g., "Fidelity", "Health Equity", "City of Burlingame")
        - account_number: Account number if present
        - invoice_number: Invoice number if present
        - type: Document type (e.g., "Bill", "Statement", "Escrow Statement")
        - other: Any other relevant identifying information

        Return ONLY valid JSON in this exact format:
        {"date": "YYYY.MM.DD", "credit_card": "", "vendor": "", "account_number": "", "invoice_number": "", "type": "", "other": ""}

        Document text:
        ---
        #{text}
        ---
      PROMPT
    end
  end
end
