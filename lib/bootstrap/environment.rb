# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# bootstrap.rb contains the minimal code to be able to launch Bundler to eventually be able
# to retrieve the core code in the logstash-core gem which can live under different paths
# depending on the launch context (local dev, packaged, etc)
require_relative "bundler"
require_relative "rubygems"
require "pathname"

module LogStash
  module Environment
    extend self

    # also set the env LOGSTASH_HOME
    LOGSTASH_HOME = ENV["LOGSTASH_HOME"] = ::File.expand_path(::File.join(__FILE__, "..", "..", ".."))

    BUNDLE_DIR = ::File.join(LOGSTASH_HOME, "vendor", "bundle")
    GEMFILE_PATH = ::File.join(LOGSTASH_HOME, "Gemfile")
    LOCAL_GEM_PATH = ::File.join(LOGSTASH_HOME, 'vendor', 'local_gems')
    CACHE_PATH = ::File.join(LOGSTASH_HOME, "vendor", "cache")
    LOCKFILE = Pathname.new(::File.join(LOGSTASH_HOME, "Gemfile.lock"))
    GEMFILE = Pathname.new(::File.join(LOGSTASH_HOME, "Gemfile"))

    # @return [String] the ruby version string bundler uses to craft its gem path
    def gem_ruby_version
      RbConfig::CONFIG["ruby_version"]
    end

    # @return [String] major.minor ruby version, ex 1.9
    def ruby_abi_version
      RUBY_VERSION[/(\d+\.\d+)(\.\d+)*/, 1]
    end

    # @return [String] jruby, ruby, rbx, ...
    def ruby_engine
      RUBY_ENGINE
    end

    def oss_only?
      return true if ENV['OSS'] == "true"

      !File.exist?(File.join(LogStash::Environment::LOGSTASH_HOME, "x-pack"))
    end

    def win_platform?
      ::Gem.win_platform?
    end

    def logstash_gem_home
      ::File.join(BUNDLE_DIR, ruby_engine, gem_ruby_version)
    end

    def vendor_path(path)
      return ::File.join(LOGSTASH_HOME, "vendor", path)
    end

    def pattern_path(path)
      return ::File.join(LOGSTASH_HOME, "patterns", path)
    end
  end
end

# when launched as a script, not require'd, (currently from bin/logstash)
if $0 == __FILE__
  bundler_options = {:without => [:build, :development]}
  ## Check for dev flags - this needs to be done before the runner is invoked to set bundler options
  if ARGV.include?("--enable-local-plugin-development")
    bundler_options[:allow_gemfile_changes] = true
  end
  LogStash::Bundler.setup!(bundler_options)
  require_relative "patches/jar_dependencies"

  require 'logstash/runner'
  exit_status = LogStash::Runner.run("bin/logstash", ARGV)
  exit(exit_status || 0)
end
