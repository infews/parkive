# frozen_string_literal: true

require_relative "lib/parkive/version"

Gem::Specification.new do |spec|
  spec.name = "parkive"
  spec.version = Parkive::VERSION
  spec.authors = ["Davis W. Frank"]
  spec.email = ["dwfrank@gmail.com"]

  spec.summary = "A util for listing, renaming, and moving personal archivables"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/infews/parkive"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = "parkive"
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  # spec.add_dependency "prompts"
  spec.add_dependency "ruby_llm"

  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "standard"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "debug"
  # spec.add_development_dependency "debase-ruby_core_source 4.0.0"


  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
