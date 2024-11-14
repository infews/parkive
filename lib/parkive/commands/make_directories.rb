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
        d = ["01.Jan", "02.Feb", "03.Mar", "04.Apr", "05.May", "06.Jun", "07.Jul", "08.Aug", "09.Sep", "10.Oct", "11.Nov", "12.Dec"]
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
