# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "paquet-test"
  spec.version       = "0.0.0"
  spec.authors       = ["Elastic"]
  spec.email         = ["info@elastic.co"]
  spec.license       = "Apache License (2.0)"

  spec.summary       = %q{testing gem}
  spec.description   = %q{testing gem}
  spec.homepage      = "https://github.com/elastic/logstash"

  spec.add_runtime_dependency "stud"
  spec.add_runtime_dependency "flores", "0.0.8"
  spec.add_runtime_dependency "logstash-devutils", "0.0.6"
end
