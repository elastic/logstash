Gem::Specification.new do |s|
  s.name        = 'logstash-integration-tests'
  s.version     = '0.1.0'
  s.licenses    = ['Apache License (2.0)']
  s.summary     = "Tests LS binary"
  s.description = "This is a Logstash integration test helper gem"
  s.authors     = [ "Elastic"]
  s.email       = 'info@elastic.co'
  s.homepage    = "http://www.elastic.co/guide/en/logstash/current/index.html"

  # Files
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Gem dependencies
  s.add_development_dependency 'elasticsearch'
  s.add_development_dependency 'childprocess'
  s.add_development_dependency 'rspec-wait'
  s.add_development_dependency 'manticore'
  s.add_development_dependency 'stud'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'flores'
end
