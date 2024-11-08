# frozen_string_literal: true

module Parkive
  module Commands
    class MakeDirectories
      def initialize(destination, year)
        @year = year
        @root_path = File.join(destination, year)
        @commands = []
      end

      def commands
        @commands << "puts #{message}"
        @commands << mkdir_command
      end

      def dirs
        d = MONTH_DIRNAMES.values
        d << "#{@year}.Media"
        d << "#{@year}.Tax"
        d.flatten
          .collect { |dir| File.join(@root_path, dir) }
      end

      def mkdir_command
        "echo \"#{dirs.join(" ")}\" | xargs mkdir -p"
      end

      def message
        "Creating archive directories in #{@root_path}"
      end
    end
  end
end
