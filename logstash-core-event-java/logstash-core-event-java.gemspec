# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logstash-core-event-java/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Elastic"]
  gem.email         = ["info@elastic.co"]
  gem.description   = %q{The core event component of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core-event-java - The core event component of logstash}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(["logstash-core-event-java.gemspec", "gemspec_jars.rb", "lib/**/*.jar", "lib/**/*.rb", "spec/**/*.rb"])
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core-event-java"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_EVENT_JAVA_VERSION

  gem.platform = "java"

  gem.add_runtime_dependency "jar-dependencies"

  # as of Feb 3rd 2016, the ruby-maven gem is resolved to version 3.3.3 and that version
  # has an rdoc problem that causes a bundler exception. 3.3.9 is the current latest version
  # which does not have this problem.
  gem.add_runtime_dependency "ruby-maven", "~> 3.3.9"

  eval(File.read(File.expand_path("../gemspec_jars.rb", __FILE__)))
end
