# frozen_string_literal: true

# @spec REN-TEXT-001, REN-TEXT-002
module Parkive
  class TextExtractor
    def self.extract(pdf_path)
      text = `pdftotext "#{pdf_path}" -`
      text.strip.empty? ? nil : text
    end
  end
end
