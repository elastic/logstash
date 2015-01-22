# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel"]
  gem.email         = ["jls@semicomplete.com"]
  gem.description   = %q{Library that contains the classes required to create LogStash events}
  gem.summary       = %q{Library that contains the classes required to create LogStash events}
  gem.homepage      = "https://github.com/logstash/logstash"
  gem.license       = "Apache License (2.0)"

  gem.files = %w{
    lib/logstash-event.rb
    lib/logstash/environment.rb
    lib/logstash/errors.rb
    lib/logstash/event.rb
    lib/logstash/java_integration.rb
    lib/logstash/json.rb
    lib/logstash/namespace.rb
    lib/logstash/timestamp.rb
    lib/logstash/version.rb
    lib/logstash/util.rb
    lib/logstash/util/accessors.rb
    lib/logstash/util/fieldreference.rb
    LICENSE
  }

  gem.test_files    = ["spec/core/event_spec.rb"]
  gem.name          = "logstash-event"
  gem.require_paths = ["lib"]
  gem.version       = "1.3.0"

  gem.add_runtime_dependency "cabin"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "guard"
  gem.add_development_dependency "guard-rspec"

  if RUBY_PLATFORM == 'java'
    gem.platform = RUBY_PLATFORM
    gem.add_runtime_dependency "jrjackson"
  else
    gem.add_runtime_dependency "oj"
  end
end
