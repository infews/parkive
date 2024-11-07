# frozen_string_literal: true

module Parkive
  module Commands
    class MakeDirectories
      def initialize(destination, year)
        @year = year
        @root_path = File.join(destination, year)
      end

      def build
        dirs = MONTH_DIRNAMES.values
        dirs << "#{@year}.Media"
        dirs << "#{@year}.Tax"

        dirs.collect { |dir| "mkdir -p #{File.join(@root_path, dir)}" }
      end
    end
  end
end
