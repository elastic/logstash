# -*- encoding: utf-8 -*-

gem_version_file = File.expand_path("GEM_BUILD_VERSION", __dir__)
unless File.exist?(gem_version_file)
  File.write(gem_version_file, ENV.fetch("GEM_BUILD_VERSION"))
end

Gem::Specification.new do |s|
  s.name            = File.basename(__FILE__, ".gemspec")
  s.version         = File.read(gem_version_file).chomp
  s.licenses        = ['Elastic-2.0']
  s.summary         = "A logstash plugin that ensures FIPS 140-3 compliance"
  s.description     = <<~DESC
    This plugin is to be included in Logstash distributions that need FedRAMP HIGH
    FIPS 140-3 compliance; its hooks run before pipelines are loaded to ensure that
    the process is running with the correct settings for cryptography.
  DESC
  s.authors         = ["Elasticsearch"]
  s.email           = 'info@elasticsearch.com'
  s.homepage        = "http://www.elasticsearch.org/guide/en/logstash/current/index.html"

  s.require_paths = ["lib"]

  # Files
  s.files = Dir::glob("lib/**/*.rb") |
            Dir::glob("*.gemspec") |
            Dir.glob("GEM_BUILD_VERSION")

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = {
    "logstash_plugin" => "true",
    "logstash_group" => "integration",
    "integration_plugins" => "", # empty; no config-accessible plugins
  }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", ">= 1.60", "<= 2.99"
end
