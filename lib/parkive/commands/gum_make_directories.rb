# frozen_string_literal: true

module Parkive
  module Commands
    class GumMakeDirectories < MakeDirectories
      def commands
        @commands << "gum style --foreground 75 \"#{message}\""
        @commands << mkdir_command
      end
    end
  end
end
