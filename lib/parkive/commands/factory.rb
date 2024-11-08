# frozen_string_literal: true

module Parkive
  module Commands
    class Factory
      def self.forMakeDirectories(gum_present)
        return GumMakeDirectories if gum_present
        MakeDirectories
      end
    end
  end
end
