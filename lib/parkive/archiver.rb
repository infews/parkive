# frozen_string_literal: true

require "forwardable"

module Parkive
  class Archiver
    extend Forwardable
    def_delegators :@paths, :<<, :first

    def initialize(paths, archive_root)
      @paths = Array(paths)
      @archive_root = archive_root
    end

    def move_to(&block)
      @paths.each_with_object(Archiver.new([], @archive_root)) do |path, remaining|
        if yield path
          FileUtils.mv(path, File.join(@archive_root, path.archive_path))
        else
          remaining << path
        end
      end
    end
  end
end
