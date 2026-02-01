# frozen_string_literal: true

# @spec REN-CLI-001, REN-CLI-002
module Parkive
  class CLI < Thor
    desc "rename DIR", "Renames PDFs in DIR based on their content to the Parkive pattern"

    def rename(directory)
      raise NoSourceDirectoryError.new(directory) unless Dir.exist?(directory)
    end
  end
end
