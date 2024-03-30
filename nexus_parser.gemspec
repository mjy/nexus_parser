# frozen_string_literal: true

require_relative "lib/nexus_parser/version"

Gem::Specification.new do |spec|
  spec.name = "nexus_parser"
  spec.version = NexusParser::VERSION
  spec.authors = ["mjy"]
  spec.email = ["diapriid@gmail.com"]

  spec.summary = "A Nexus file format (phylogenetic inference) parser in Ruby."
  spec.description = "A full featured and extensible Nexus file parser in Ruby."
  spec.homepage = "http://github.com/mjy/nexus_parser"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.extra_rdoc_files = [
    "LICENSE",
    "README",
    "README.rdoc"
  ]
  spec.files = [
    ".document",
    ".gitignore",
    "LICENSE",
    "MIT-LICENSE",
    "README",
    "README.rdoc",
    "Rakefile",
    "install.rb",
    "lib/nexus_parser.rb",
    "lib/nexus_parser/lexer.rb",
    "lib/nexus_parser/parser.rb",
    "lib/nexus_parser/tokens.rb",
    "lib/nexus_parser/version.rb",
    "nexus_parser.gemspec",
    "tasks/nexus_parser_tasks.rake",
    "test/MX_test_03.nex",
    "test/test.nex",
    "test/test_nexus_parser.rb",
    "uninstall.rb"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.rdoc_options = ["--charset=UTF-8"]
  spec.require_paths = ["lib"]
  spec.rubygems_version = "1.5.3"

  spec.test_files = [
    "test/test_nexus_parser.rb"
  ]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
end

