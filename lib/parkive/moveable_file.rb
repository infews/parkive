# frozen_string_literal: true

module Parkive
  class MoveableFile
    attr_accessor :move

    def initialize
      @move = false
    end

    def move?
      move
    end
  end
end
