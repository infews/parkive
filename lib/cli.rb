require "thor"
require "thor/actions"

require_relative "thor_ext"
require_relative "cli/make_directories"
require_relative "cli/store"

module Parkive
  class CLI < Thor
    extend ThorExt::Start
    def self.exit_on_failure?
      true
    end
  end
end
