# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logstash-core/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Elastic"]
  gem.email         = ["info@elastic.co"]
  gem.description   = %q{The core components of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core - The core components of logstash}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(["logstash-core.gemspec", "gemspec_jars.rb", "lib/**/*.rb", "spec/**/*.rb", "locales/*", "lib/logstash/api/init.ru", "lib/logstash-core/logstash-core.jar"])
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_VERSION

  gem.platform = "java"

  gem.add_runtime_dependency "pry", "~> 0.10.1"  #(Ruby license)
  gem.add_runtime_dependency "stud", "~> 0.0.19" #(Apache 2.0 license)
  gem.add_runtime_dependency "clamp", "~> 0.6.5" #(MIT license) for command line args/flags
  gem.add_runtime_dependency "filesize", "0.0.4" #(MIT license) for :bytes config validator
  gem.add_runtime_dependency "gems", "~> 0.8.3"  #(MIT license)
  gem.add_runtime_dependency "concurrent-ruby", "1.0.0"
  gem.add_runtime_dependency "sinatra", '~> 1.4', '>= 1.4.6'
  gem.add_runtime_dependency 'puma', '~> 2.16'
  gem.add_runtime_dependency "jruby-openssl", "0.9.16" # >= 0.9.13 Required to support TLSv1.2
  gem.add_runtime_dependency "chronic_duration", "0.10.6"
  gem.add_runtime_dependency "jrmonitor", '~> 0.4.2'

  # TODO(sissel): Treetop 1.5.x doesn't seem to work well, but I haven't
  # investigated what the cause might be. -Jordan
  gem.add_runtime_dependency "treetop", "< 1.5.0" #(MIT license)

  # upgrade i18n only post 0.6.11, see https://github.com/svenfuchs/i18n/issues/270
  gem.add_runtime_dependency "i18n", "= 0.6.9" #(MIT license)

  # filetools and rakelib
  gem.add_runtime_dependency "minitar", "~> 0.5.4"
  gem.add_runtime_dependency "rubyzip", "~> 1.1.7"
  gem.add_runtime_dependency "thread_safe", "~> 0.3.5" #(Apache 2.0 license)

  gem.add_runtime_dependency "jrjackson", "~> 0.4.0" #(Apache 2.0 license)

  gem.add_runtime_dependency "jar-dependencies"
  # as of Feb 3rd 2016, the ruby-maven gem is resolved to version 3.3.3 and that version
  # has an rdoc problem that causes a bundler exception. 3.3.9 is the current latest version
  # which does not have this problem.
  gem.add_runtime_dependency "ruby-maven", "~> 3.3.9"

  eval(File.read(File.expand_path("../gemspec_jars.rb", __FILE__)))
end
