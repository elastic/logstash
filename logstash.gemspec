# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel", "Pete Fritchman"]
  gem.email         = ["jls@semicomplete.com", "petef@databits.net"]
  gem.description   = %q{scalable log and event management (search, archive, pipeline)}
  gem.summary       = %q{logstash - log and event management}
  gem.homepage      = "http://logstash.net/"
  gem.license       = "Apache License (2.0)"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION

  # Core dependencies
  gem.add_runtime_dependency "cabin", [">=0.6.0"]   #(Apache 2.0 license)
  gem.add_runtime_dependency "json"               #(ruby license)
  gem.add_runtime_dependency "minitest"           # for running the tests from the jar, (MIT license)
  gem.add_runtime_dependency "pry"                #(ruby license)
  gem.add_runtime_dependency "stud"               #(Apache 2.0 license)
  gem.add_runtime_dependency "clamp"              # for command line args/flags (MIT license)
  gem.add_runtime_dependency "i18n"               #(MIT license)
  gem.add_runtime_dependency "treetop"

  gem.platform = RUBY_PLATFORM
end
