# frozen_string_literal: true

# @spec REN-TEXT-001, REN-TEXT-002
module Parkive
  class TextExtractor
    def self.extract(pdf_path)
      text = `pdftotextd -f 1 -l 1 "#{pdf_path}" -`
      text.strip.empty? ? nil : text
    end
  end
end
