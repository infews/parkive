# frozen_string_literal: true

module Parkive
  class CLI < Thor
    # include Thor::Actions

    desc "make_directories DST", "Creates archive sub-directories in DST for the given year"
    method_option :year, default: Time.now.year.to_s, desc: "Year folder to create; default is this year"

    def make_directories(destination)
      raise NoDestinationDirectoryError.new(destination) unless Dir.exist?(destination)

      dest = File.join(destination, options[:year])
      Dir.mkdir(dest)

      ["01.Jan", "02.Feb", "03.Mar", "04.Apr", "05.May", "06.Jun", "07.Jul", "08.Aug", "09.Sep", "10.Oct", "11.Nov", "12.Dec", "#{options[:year]}.Media", "#{options[:year]}.Tax"].each { |dir| Dir.mkdir(File.join(destination, options[:year], dir)) }
    end

    # TODO: not sure how to test this
    map :mkdir => :make_directories
  end
end