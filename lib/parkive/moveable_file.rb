# frozen_string_literal: true

module Parkive
  class MoveableFile
    attr_accessor :move
    attr_reader :path

    def initialize(path)
      @move = false
      @path = path
    end

    def move?
      move
    end

    def exist?
      File.exist?(path)
    end
  end
end
