# frozen_string_literal: true

require_relative "parkive/version"
require_relative "parkive/commands"
require_relative "cli"

module Parkive
  class NoDestinationDirectoryError < StandardError
    def initialize(path)
      super("Destination directory #{path} does not exist")
    end
  end

  MONTH_DIRNAMES = {
    "01" => "01.Jan",
    "02" => "02.Feb",
    "03" => "03.Mar",
    "04" => "04.Apr",
    "05" => "05.May",
    "06" => "06.Jun",
    "07" => "07.Jul",
    "08" => "08.Aug",
    "09" => "09.Sep",
    "10" => "10.Oct",
    "11" => "11.Nov",
    "12" => "12.Dec"
  }.freeze
end
