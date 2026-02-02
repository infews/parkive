# frozen_string_literal: true

# @spec REN-TEXT-001
module Parkive
  class TextExtractor
    def self.extract(pdf_path)
      `pdftotext "#{pdf_path}" -`
    end
  end
end
