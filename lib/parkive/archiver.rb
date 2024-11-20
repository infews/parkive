# frozen_string_literal: true

require "forwardable"
require "rainbow"

module Parkive
  class Archiver
    extend Forwardable
    def_delegators :@paths, :<<, :first, :[]

    def initialize(paths:, archive_root:, verbose: false)
      @paths = Array(paths)
      @archive_root = archive_root
      @verbose = verbose
    end

    def store(&block)
      @paths.each_with_object(Archiver.new(paths: [], archive_root: @archive_root, verbose: @verbose)) do |path, remaining|
        if yield path
          FileUtils.mv(path, File.join(@archive_root, path.archive_path))
          puts("Moving to " + Rainbow(File.join(path.archive_path, path.basename)).cyan) if @verbose
        else
          remaining << path
          puts("File exists. Skipping " + Rainbow(path.basename).yellow) if @verbose
        end
      end
    end

    def store_all
      store { true }
    end

    def collect(&block)
      @paths.each_with_object(Archiver.new(paths: [], archive_root: @archive_root, verbose: @verbose)) do |path, mapped|
        yield path
        mapped << path
      end
    end
  end
end
