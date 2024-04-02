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

  spec.test_files = [
    "test/test_nexus_parser.rb"
  ]

  spec.required_ruby_version = '>= 3.3.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rdoc', '~> 6.6.2'
  spec.add_development_dependency 'byebug', '~> 11.1'
end

