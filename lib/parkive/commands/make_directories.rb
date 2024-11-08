# frozen_string_literal: true

module Parkive
  module Commands
    class MakeDirectories
      def initialize(destination, year)
        @year = year
        @root_path = File.join(destination, year)
        @commands = []
      end

      def build
        @commands << "echo \"#{dirs.join(" ")}\" | xargs mkdir -p"
      end

      def dirs
        d = MONTH_DIRNAMES.values
        d << "#{@year}.Media"
        d << "#{@year}.Tax"
        d.flatten
          .collect { |dir| File.join(@root_path, dir) }
      end
    end
  end
end
