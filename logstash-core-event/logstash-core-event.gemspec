# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logstash-core-event/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel", "Pete Fritchman", "Elasticsearch"]
  gem.email         = ["jls@semicomplete.com", "petef@databits.net", "info@elasticsearch.com"]
  gem.description   = %q{The core event component of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core-event - The core event component of logstash}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(["logstash-core-event.gemspec", "lib/**/*.rb", "spec/**/*.rb"])
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core-event"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_EVENT_VERSION

  if RUBY_PLATFORM == 'java'
    gem.platform = RUBY_PLATFORM
  end
end
