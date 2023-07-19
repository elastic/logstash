Gem::Specification.new do |s|
  s.name            = 'logstash-filter-dummy'
  s.version         = '0.1.1'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "This plugin is only used in logstash-docgen test"
  s.description     = "This plugin is only used in logstash-docgen test"

  s.authors       = ["Elastic"]
  s.email         = ["info@elastic.co"]

  s.homepage = "http://www.elasticsearch.org/guide/en/logstash/current/index.html"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir["lib/**/*", "spec/**/*", "*.gemspec", "*.md", "CONTRIBUTORS", "Gemfile", "LICENSE", "NOTICE.TXT", "vendor/jar-dependencies/**/*.jar", "vendor/jar-dependencies/**/*.rb", "VERSION"]

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"
end
