require "pathname"
require "date"

module Parkive
  class ArchivablePathname < Pathname

    def self.from(paths)
      Array(paths).collect { |path| new(path) }
                  .select(&:is_archivable?)
    end

    def initialize(path)
      super
      @date = extract_date_from(File.basename(path))
    end

    def is_archivable?
      @date.is_a? Date
    end

    def archive_path
      return "" unless is_archivable? # TODO: Should this be a raise?

      year = @date.strftime("%Y")
      month = "#{@date.strftime('%m')}.#{@date.strftime('%b')}"
      File.join(year, month)
    end

    private

    def extract_date_from(path)
      Date.strptime(path, "%Y.%m.%d")
    rescue Date::Error
      nil
    end
  end
end