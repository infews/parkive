# frozen_string_literal: true

module Parkive
  module Commands
    class GumMakeDirectories
      def initialize(destination, year)
        @year = year
        @root_path = File.join(destination, year)
        @commands = []
        @vanilla = MakeDirectories.new(destination, year)
      end

      def build
        dirs = @vanilla.dirs.collect { |dir| File.join(@root_path, dir) }

        @commands << "gum style --foreground=\"0000ff\" \"Creating archive directories in #{@root_path}\""
        @commands << "echo \"#{dirs.join(" ")}\" | xargs mkdir -p"
      end
    end
  end
end
