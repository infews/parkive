# frozen_string_literal: true

require "ruby_llm/schema"

module Parkive
  class DocumentFieldsSchema < RubyLLM::Schema
    description "Structured fields extracted from a financial document or invoice"

    string :date,
      description: "Statement or document date in YYYY.MM.DD format. Convert dates like '02/17/25' to '2025.02.17', 'February 17, 2025' to '2025.02.17'. Use the statement closing date. Empty string if not found."

    string :credit_card,
      description: "Credit card network or issuer: 'Visa', 'American Express', 'Master Card', 'Apple Card'. This is the payment network, NOT the card product name. Empty string if not a credit card statement."

    string :vendor,
      description: "The brand or product name on the statement, such as 'Delta SkyMiles', 'Fidelity', 'E*Trade', 'Sals Landscaping'. For credit cards, this is the card product name (e.g. 'Delta SkyMiles'), not the issuer. Empty string if not found."

    string :account_number,
      description: "Primary account number, typically the shortest unique identifier. Omit trailing sub-account suffixes like '-201'. Remove whitespace. Empty string if not found."

    string :invoice_number,
      description: "Invoice number with whitespace removed. Empty string if not found."
  end
end
