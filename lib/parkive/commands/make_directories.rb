# frozen_string_literal: true

module Parkive
  module Commands
    DIRECTORIES = %w[
      01.Jan
      02.Feb
      03.Mar
      04.Apr
      05.May
      06.Jun
      07.Jul
      08.Aug
      09.Sep
      10.Oct
      11.Nov
      12.Dec
    ]

    def self.make_directories(archive_root:, year:, verbose:)
      archive_paths = DIRECTORIES.collect { |dir| File.join(archive_root, year, dir) }
      archive_paths << File.join(archive_root, year, "#{year}.Media")
      archive_paths << File.join(archive_root, year, "#{year}.Tax")

      puts Rainbow("Making archive directories in #{archive_root}/#{year}.").cyan if verbose

      FileUtils.mkdir_p(archive_paths)
    end
  end
end
