# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "logstash-input-packtest"
  spec.version       = "0.0.1"
  spec.authors       = ["Elastic"]
  spec.email         = ["info@elastic.co"]
  spec.summary       = "a summary"
  spec.description   = "a description"
  spec.homepage      = "https://elastic.co"

  spec.add_runtime_dependency "logstash-input-packtestdep"
end
