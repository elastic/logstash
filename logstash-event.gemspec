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
    lib/logstash/event.rb
    lib/logstash/namespace.rb
    lib/logstash/util/fieldreference.rb
    lib/logstash/util.rb
    spec/event.rb
    LICENSE
  }

  gem.test_files    = []
  gem.name          = "logstash-event"
  gem.require_paths = ["lib"]
  gem.version       = "1.2.02"
  
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "guard"
  gem.add_development_dependency "guard-rspec"
  gem.add_development_dependency "insist", "1.0.0"
end
