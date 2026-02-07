# frozen_string_literal: true

# @spec REN-NAME-001, REN-NAME-002, REN-NAME-003, REN-NAME-004, REN-NAME-006
module Parkive
  class NameSuggestor
    FIELD_ORDER = %w[date credit_card vendor account_number invoice_number].freeze
    UNSAFE_CHARS = %r{[/\\:*?"<>|]}
    DATE_PATTERN = /^\d{4}\.\d{2}\.\d{2}$/

    def self.suggest(fields)
      parts = FIELD_ORDER
        .map { |key| fields[key] }
        .compact
        .reject { |v| v.to_s.empty? }
        .map { |v| sanitize(v) }

      # @spec REN-NAME-006
      if parts.empty? || !valid_date?(parts[0])
        parts.unshift("UNKNOWN")
      end

      "#{parts.join('.')}.pdf"
    end

    def self.valid_date?(str)
      str.to_s.match?(DATE_PATTERN)
    end

    # @spec REN-NAME-003, REN-NAME-004, REN-NAME-005
    def self.sanitize(str)
      str.to_s
         .gsub(/\s+/, ".")
         .gsub(UNSAFE_CHARS, "")
         .gsub(/\.+/, ".")
    end
  end
end
