
Gem::Specification.new do |s|
  s.name            = "logstash-integration-failure_injector"
  s.version         = "0.0.1"
  s.licenses        = ["Apache-2.0"]
  s.summary         = "A collection of Logstash plugins that halp simulating abnormal cases during the tests."
  s.description     = "This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname."
  s.authors         = ["Elastic"]
  s.email           = "info@elastic.co"
  s.homepage        = "https://www.elastic.co/logstash"
  s.metadata        = {
    "logstash_plugin" => "true",
    "logstash_group" => "integration",
    "integration_plugins" => %w(
      logstash-filter-failure_injector
      logstash-output-failure_injector
    ).join(",")
  }

  s.files           = Dir["lib/**/*","spec/**/*","*.gemspec"]
  s.test_files      = s.files.grep(%r{^(test|spec|features)/})

  s.add_runtime_dependency "logstash-core-plugin-api", ">= 2.1.12", "<= 2.99"

  s.add_development_dependency "logstash-devutils"
end
