# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "logstash-core-plugin-api/version"

Gem::Specification.new do |gem|
  gem.authors       = ["Elastic"]
  gem.email         = ["info@elastic.co"]
  gem.description   = %q{Logstash plugin API}
  gem.summary       = %q{Define the plugin API that the plugin need to follow.}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(["logstash-core-plugin-api.gemspec", "lib/**/*.rb", "spec/**/*.rb"])
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core-plugin-api"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_PLUGIN_API

  gem.add_runtime_dependency "logstash-core", "5.4.0"

  # Make sure we dont build this gem from a non jruby
  # environment.
  if RUBY_PLATFORM == "java"
    gem.platform = "java"
  else
    raise "The logstash-core-api need to be build on jruby"
  end
end
