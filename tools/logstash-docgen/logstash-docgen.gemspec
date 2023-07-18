# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "logstash/docgen/version"

Gem::Specification.new do |spec|
  spec.name          = "logstash-docgen"
  spec.version       = Logstash::Docgen::VERSION
  spec.authors       = ["Elastic"]
  spec.email         = ["info@elastic.co"]

  spec.summary       = %q{Logstash Tooling to generate the documentation of a plugin}
  spec.homepage      = "https://elastic.co/logstash"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "clamp"
  spec.add_runtime_dependency "stud"
  spec.add_runtime_dependency "git"
  spec.add_runtime_dependency "asciidoctor"
  spec.add_runtime_dependency "pry"
  spec.add_runtime_dependency "addressable"
  spec.add_runtime_dependency "octokit", "~> 3.8.0"

  # gems 1.0.0 requires Ruby 2.1.9 or newer, so we pin down.
  spec.add_runtime_dependency "gems", "0.8.3"

  spec.add_development_dependency "rake", "~> 12"
  spec.add_development_dependency "rspec"

  # Used for the dependency lookup code
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock", "2.2.0"
end
