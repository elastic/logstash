# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel"]
  gem.email         = ["jls@semicomplete.com"]
  gem.description   = %q{Library that contains the classes required to create LogStash events}
  gem.summary       = %q{Library that contains the classes required to create LogStash events}
  gem.homepage      = "https://github.com/logstash/logstash"

  gem.files = %w{
    lib/logstash-event.rb
    lib/logstash/event.rb
    lib/logstash/namespace.rb
    lib/logstash/time.rb
    lib/logstash/version.rb
    LICENSE
  }

  gem.test_files    = []
  gem.name          = "logstash-event"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION
end
