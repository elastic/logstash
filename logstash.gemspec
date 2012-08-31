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
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION

  # Core dependencies
  gem.add_runtime_dependency "cabin", ["0.4.4"]
  gem.add_runtime_dependency "json"
  gem.add_runtime_dependency "minitest" # for running the tests from the jar
  gem.add_runtime_dependency "pry"

  # Web dependencies
  gem.add_runtime_dependency "ftw", ["~> 0.0.19"]
  gem.add_runtime_dependency "haml"
  gem.add_runtime_dependency "rack"
  gem.add_runtime_dependency "sass"
  gem.add_runtime_dependency "sinatra"

  # Input/Output/Filter dependencies
  #TODO Can these be optional?
  gem.add_runtime_dependency "aws-sdk"
  gem.add_runtime_dependency "heroku"
  gem.add_runtime_dependency "addressable", ["2.2.6"]
  gem.add_runtime_dependency "bunny"
  gem.add_runtime_dependency "ffi"
  gem.add_runtime_dependency "ffi-rzmq", ["0.9.3"]
  gem.add_runtime_dependency "filewatch", ["0.3.4"]
  gem.add_runtime_dependency "gelfd", ["0.2.0"]
  gem.add_runtime_dependency "gelf", ["1.3.2"]
  gem.add_runtime_dependency "gmetric", ["0.1.3"]
  gem.add_runtime_dependency "jls-grok", ["0.10.7"]
  gem.add_runtime_dependency "mail"
  gem.add_runtime_dependency "mongo"
  gem.add_runtime_dependency "onstomp"
  gem.add_runtime_dependency "redis"
  gem.add_runtime_dependency "riak-client", ["1.0.3"]
  gem.add_runtime_dependency "riemann-client", ["0.0.6"]
  gem.add_runtime_dependency "statsd-ruby", ["0.3.0"]
  gem.add_runtime_dependency "uuidtools" # For generating amqp queue names
  gem.add_runtime_dependency "xml-simple"
  gem.add_runtime_dependency "xmpp4r", ["0.5"]

  if RUBY_PLATFORM == 'java'
    gem.platform = RUBY_PLATFORM
    gem.add_runtime_dependency "jruby-elasticsearch", ["0.0.14"]
    gem.add_runtime_dependency "jruby-httpclient"
    gem.add_runtime_dependency "jruby-openssl"
    gem.add_runtime_dependency "jruby-win32ole"
  else
    gem.add_runtime_dependency "excon"
  end

  if RUBY_VERSION >= '1.9.1'
    gem.add_runtime_dependency "cinch" # cinch requires 1.9.1+
  end

  gem.add_development_dependency "mocha"
  gem.add_development_dependency "shoulda"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "insist", "0.0.6"
end
