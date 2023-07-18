# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paquet/version'

Gem::Specification.new do |spec|
  spec.name          = "paquet"
  spec.version       = Paquet::VERSION
  spec.authors       = ["Elastic"]
  spec.email         = ["info@elastic.co"]
  spec.license       = "Apache License (2.0)"

  spec.summary       = %q{Rake helpers to create a uber gem}
  spec.description   = %q{This gem add a few rake tasks to create a uber gems that will be shipped as a zip}
  spec.homepage      = "https://github.com/elastic/logstash"

  spec.files         = Dir.glob(File.join(File.dirname(__FILE__), "lib", "**", "*.rb"))

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "webmock", "~> 2.2.0"
  spec.add_development_dependency "stud"
end
