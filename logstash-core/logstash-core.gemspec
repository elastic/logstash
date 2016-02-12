# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logstash-core/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel", "Pete Fritchman", "Elasticsearch"]
  gem.email         = ["jls@semicomplete.com", "petef@databits.net", "info@elasticsearch.com"]
  gem.description   = %q{The core components of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core - The core components of logstash}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(["logstash-core.gemspec", "lib/**/*.rb", "spec/**/*.rb", "locales/*"])
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_VERSION

  gem.add_runtime_dependency "logstash-core-event", "~> 2.2.1"

  gem.add_runtime_dependency "cabin", "~> 0.7.0" #(Apache 2.0 license)
  gem.add_runtime_dependency "pry", "~> 0.10.1"  #(Ruby license)
  gem.add_runtime_dependency "stud", "~> 0.0.19" #(Apache 2.0 license)
  gem.add_runtime_dependency "clamp", "~> 0.6.5" #(MIT license) for command line args/flags
  gem.add_runtime_dependency "filesize", "0.0.4" #(MIT license) for :bytes config validator
  gem.add_runtime_dependency "gems", "~> 0.8.3"  #(MIT license)
  gem.add_runtime_dependency "concurrent-ruby", "0.9.2"
  gem.add_runtime_dependency "jruby-openssl", "0.9.13" # Required to support TLSv1.2

  # TODO(sissel): Treetop 1.5.x doesn't seem to work well, but I haven't
  # investigated what the cause might be. -Jordan
  gem.add_runtime_dependency "treetop", "< 1.5.0" #(MIT license)

  # upgrade i18n only post 0.6.11, see https://github.com/svenfuchs/i18n/issues/270
  gem.add_runtime_dependency "i18n", "= 0.6.9" #(MIT license)

  # filetools and rakelib
  gem.add_runtime_dependency "minitar", "~> 0.5.4"
  gem.add_runtime_dependency "rubyzip", "~> 1.1.7"
  gem.add_runtime_dependency "thread_safe", "~> 0.3.5" #(Apache 2.0 license)

  if RUBY_PLATFORM == 'java'
    gem.platform = RUBY_PLATFORM
    gem.add_runtime_dependency "jrjackson", "~> 0.3.7" #(Apache 2.0 license)
  else
    gem.add_runtime_dependency "oj" #(MIT-style license)
  end

  if RUBY_ENGINE == "rbx"
    # rubinius puts the ruby stdlib into gems.
    gem.add_runtime_dependency "rubysl"

    # Include racc to make the xml tests pass.
    # https://github.com/rubinius/rubinius/issues/2632#issuecomment-26954565
    gem.add_runtime_dependency "racc"
  end
end
