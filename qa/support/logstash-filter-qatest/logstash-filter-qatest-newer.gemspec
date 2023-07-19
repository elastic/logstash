Gem::Specification.new do |s|
  s.name            = 'logstash-filter-qatest'
  s.version         = '0.1.1'
  s.licenses        = ['Apache License (2.0)']
  s.summary         = "This plugin is only used in the acceptance test"
  s.description     = "This plugin is only used in the acceptance test"
  s.authors         = ["Elasticsearch"]
  s.email           = 'info@elasticsearch.com'
  s.homepage        = "http://www.elasticsearch.org/guide/en/logstash/current/index.html"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\) + ::Dir.glob('vendor/*')

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "filter" }

  # Gem dependencies
  s.add_development_dependency 'logstash-devutils'
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
end
