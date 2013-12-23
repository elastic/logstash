# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel"]
  gem.email         = ["jls@semicomplete.com"]
  gem.description   = "gem containing logstash code mainly for the purposes of doing programmatic validation of configuration. This gem aims to include all plugins but just enough rubygem dependencies to permit validation."
  gem.summary       = %q{yes}
  gem.homepage      = "http://logstash.net/"
  gem.license       = "Apache License (2.0)"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-lib"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION

  # Core dependencies
  gem.add_runtime_dependency "cabin", [">=0.6.0"]   #(Apache 2.0 license)
  gem.add_runtime_dependency "json"               #(ruby license)
  gem.add_runtime_dependency "stud"               #(Apache 2.0 license)
  gem.add_runtime_dependency "i18n"               #(MIT license)
  gem.add_runtime_dependency "treetop"
end
