# frozen_string_literal: true

module Parkive
  module Commands
    class GumMakeDirectories < MakeDirectories
      def commands
        @commands << "gum style --foreground=\"0000ff\" \"Creating archive directories in #{@root_path}\""
        super
      end
    end
  end
end
