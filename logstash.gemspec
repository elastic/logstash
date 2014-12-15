# -*- encoding: utf-8 -*-
require File.expand_path('../lib/logstash/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jordan Sissel", "Pete Fritchman"]
  gem.email         = ["jls@semicomplete.com", "petef@databits.net"]
  gem.description   = %q{scalable log and event management (search, archive, pipeline)}
  gem.summary       = %q{logstash - log and event management}
  gem.homepage      = "http://logstash.net/"
  gem.license       = "Apache License (2.0)"

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "logstash"
  gem.require_paths = ["lib"]
  gem.version       = LOGSTASH_VERSION

  # Core dependencies
  gem.add_runtime_dependency "cabin", [">=0.6.0"] #(Apache 2.0 license)
  gem.add_runtime_dependency "minitest"           #(MIT license) for running the tests from the jar,
  gem.add_runtime_dependency "pry"                #(Ruby license)
  gem.add_runtime_dependency "stud"               #(Apache 2.0 license)
  gem.add_runtime_dependency "clamp"              #(MIT license) for command line args/flags

  # upgrade i18n only post 0.6.11, see https://github.com/svenfuchs/i18n/issues/270
  gem.add_runtime_dependency "i18n", ["=0.6.9"]   #(MIT license)

  # Web dependencies
  gem.add_runtime_dependency "ftw", ["~> 0.0.40"] #(Apache 2.0 license)
  gem.add_runtime_dependency "mime-types"         #(GPL 2.0)
  gem.add_runtime_dependency "rack"               #(MIT-style license)
  gem.add_runtime_dependency "sinatra"            #(MIT-style license)

  # Plugin manager dependencies

  # jar-dependencies 0.1.2 is included in jruby 1.7.6 no need to include here and
  # this avoids the gemspec jar path parsing issue of jar-dependencies 0.1.2
  #
  gem.add_runtime_dependency "jar-dependencies", ["= 0.1.2"]   #(MIT license)

  gem.add_runtime_dependency "ruby-maven"                       #(EPL license)
  gem.add_runtime_dependency "maven-tools"
  gem.add_runtime_dependency "minitar"
  gem.add_runtime_dependency "file-dependencies"

  if RUBY_PLATFORM == 'java'
    gem.platform = RUBY_PLATFORM

    # bouncy-castle-java 1.5.0147 and jruby-openssl 0.9.5 are included in jruby 1.7.6 no need to include here
    # and this avoids the gemspec jar path parsing issue of jar-dependencies 0.1.2
    #
    # gem.add_runtime_dependency "bouncy-castle-java", ["~> 1.5.0147"] #(MIT license)
    # gem.add_runtime_dependency "jruby-openssl", ["~> 0.9.5"]         #(CPL/GPL/LGPL license)

    gem.add_runtime_dependency "jruby-httpclient"                    #(Apache 2.0 license)
    gem.add_runtime_dependency "msgpack-jruby"                       #(Apache 2.0 license)
    gem.add_runtime_dependency "jrjackson"                           #(Apache 2.0 license)
  else
    gem.add_runtime_dependency "excon"    #(MIT license)
    gem.add_runtime_dependency "msgpack"  #(Apache 2.0 license)
    gem.add_runtime_dependency "oj"       #(MIT-style license)
  end

  if RUBY_ENGINE == "rbx"
    # rubinius puts the ruby stdlib into gems.
    gem.add_runtime_dependency "rubysl"

    # Include racc to make the xml tests pass.
    # https://github.com/rubinius/rubinius/issues/2632#issuecomment-26954565
    gem.add_runtime_dependency "racc"
  end

  # These are runtime-deps so you can do 'java -jar logstash.jar rspec <test>'
  gem.add_runtime_dependency "spoon"              #(Apache 2.0 license)
  gem.add_runtime_dependency "mocha"              #(MIT license)
  gem.add_runtime_dependency "shoulda"            #(MIT license)
  gem.add_runtime_dependency "rspec", "~> 2.14.0" #(MIT license)
  gem.add_runtime_dependency "insist", "1.0.0"    #(Apache 2.0 license)
  gem.add_runtime_dependency "rumbster"           #(Apache 2.0 license) For faking smtp in email tests

  gem.add_runtime_dependency "logstash-devutils"

  # Jenkins Deps
  gem.add_runtime_dependency "ci_reporter", "1.9.3"

  # Development Deps
  # coveralls temporarily disabled because of Bundler bug with "without development" and gemspec
  # gem.add_development_dependency "coveralls"
end
