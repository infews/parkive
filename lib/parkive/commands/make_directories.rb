# frozen_string_literal: true

module Parkive
  module Commands
    class MakeDirectories
      def initialize(destination, year)
        @year = year
        @root_path = File.join(destination, year)
      end

      def build
        dirs.collect { |dir| "mkdir -p #{File.join(@root_path, dir)}" }
      end

      def dirs
        d = MONTH_DIRNAMES.values
        d << "#{@year}.Media"
        d << "#{@year}.Tax"
        d.flatten
      end
    end
  end
end
