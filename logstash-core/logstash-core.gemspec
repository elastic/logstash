# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

project_versions_yaml_path = File.expand_path("../versions.yml", File.dirname(__FILE__))
if File.exist?(project_versions_yaml_path)
  # we need to copy the project level versions.yml into the gem root
  # to be able to package it into the gems file structure
  # as the require 'logstash-core/version' loads the yaml file from within the gem root.
  #
  # we ignore the copy in git and we overwrite an existing file
  # each time we build the logstash-core gem
  original_lines = IO.readlines(project_versions_yaml_path)
  original_lines << ""
  original_lines << "# This is a copy the project level versions.yml into this gem's root and it is created when the gemspec is evaluated."
  gem_versions_yaml_path = File.expand_path("./versions-gem-copy.yml", File.dirname(__FILE__))
  File.open(gem_versions_yaml_path, 'w') do |new_file|
    # create or overwrite
    new_file.puts(original_lines)
  end
end

require 'logstash-core/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Elastic"]
  gem.email         = ["info@elastic.co"]
  gem.description   = %q{The core components of logstash, the scalable log and event management tool}
  gem.summary       = %q{logstash-core - The core components of logstash}
  gem.homepage      = "http://www.elastic.co/guide/en/logstash/current/index.html"
  gem.license       = "Apache License (2.0)"

  gem.files         = Dir.glob(
    %w(versions-gem-copy.yml logstash-core.gemspec gemspec_jars.rb lib/**/*.rb spec/**/*.rb locales/*
    lib/logstash/api/init.ru lib/logstash-core/logstash-core.jar)
  )
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash-core"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_CORE_VERSION.gsub("-", ".")

  gem.platform = "java"

  gem.add_runtime_dependency "pry", "~> 0.10.1"  #(Ruby license)
  gem.add_runtime_dependency "stud", "~> 0.0.19" #(Apache 2.0 license)
  gem.add_runtime_dependency "clamp", "~> 0.6.5" #(MIT license) for command line args/flags
  gem.add_runtime_dependency "filesize", "0.0.4" #(MIT license) for :bytes config validator
  gem.add_runtime_dependency "gems", "~> 0.8.3"  #(MIT license)
  gem.add_runtime_dependency "concurrent-ruby", "~> 1.0", ">= 1.0.5"

  # Later versions are ruby 2.0 only. We should remove the rack dep once we support 9k
  gem.add_runtime_dependency "rack", '1.6.6'

  gem.add_runtime_dependency "sinatra", '~> 1.4', '>= 1.4.6'
  gem.add_runtime_dependency 'puma', '~> 2.16'
  gem.add_runtime_dependency "jruby-openssl", ">= 0.9.20" # >= 0.9.13 Required to support TLSv1.2
  gem.add_runtime_dependency "chronic_duration", "0.10.6"

  # TODO(sissel): Treetop 1.5.x doesn't seem to work well, but I haven't
  # investigated what the cause might be. -Jordan
  gem.add_runtime_dependency "treetop", "< 1.5.0" #(MIT license)

  # upgrade i18n only post 0.6.11, see https://github.com/svenfuchs/i18n/issues/270
  gem.add_runtime_dependency "i18n", "= 0.6.9" #(MIT license)

  # filetools and rakelib
  gem.add_runtime_dependency "minitar", "~> 0.6.1"
  gem.add_runtime_dependency "rubyzip", "~> 1.2.1"
  gem.add_runtime_dependency "thread_safe", "~> 0.3.5" #(Apache 2.0 license)

  gem.add_runtime_dependency "jrjackson", "~> #{ALL_VERSIONS.fetch('jrjackson')}" #(Apache 2.0 license)

  gem.add_runtime_dependency "elasticsearch", "~> 5.0", ">= 5.0.4" # Ruby client for ES (Apache 2.0 license)
  gem.add_runtime_dependency "manticore", '>= 0.5.4', '< 1.0.0'
end
