# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel", "Pete Fritchman", "Elasticsearch"]
  gem.email         = ["jls@semicomplete.com", "petef@databits.net", "info@elasticsearch.com"]
  gem.description   = %q{The core components of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core - The core components of logstash}
  gem.homepage      = "http://logstash.net/"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob("lib/**/*.rb")
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION
end
