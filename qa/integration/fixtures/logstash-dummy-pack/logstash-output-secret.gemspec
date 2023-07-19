Gem::Specification.new do |s|
  s.name          = 'logstash-output-secret'
  s.version       = '0.1.0'
  s.licenses      = ['Apache License (2.0)']
  s.summary       = 'Write a short summary, because Rubygems requires one.'
  s.description   = 'Write a longer description or delete this line.'
  s.homepage      = 'https://github.com/ph/secret'
  s.authors       = ['Pier-Hugues Pellerin']
  s.email         = 'phpellerin@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*', 'spec/**/*', '*.gemspec', '*.md', 'CONTRIBUTORS', 'Gemfile', 'LICENSE', 'NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }
  s.post_install_message = <<eos
This plugins will require the configuration of XXXXX in the logstash.yml

Make sure you double check your configuration
eos

  # Gem dependencies
  s.add_runtime_dependency "manticore"
  s.add_runtime_dependency "gemoji", "< 2.0"

  s.add_development_dependency "paquet"
  s.add_development_dependency "rake"
end
