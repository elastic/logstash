# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logstash-core-queue-jruby/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Elastic"]
  gem.email         = ["info@elastic.co"]
  gem.description   = %q{The core event component of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core-event-java - The core event component of logstash}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(["logstash-core-queue-jruby.gemspec", "gemspec_jars.rb", "lib/**/*.jar", "lib/**/*.rb", "spec/**/*.rb"])
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core-queue-jruby"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_QUEUE_JRUBY_VERSION

  gem.platform = "java"

  eval(File.read(File.expand_path("../gemspec_jars.rb", __FILE__)))
end
