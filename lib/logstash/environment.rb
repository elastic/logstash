require "logstash/errors"
require 'logstash/version'

# monkey patch RubyGems to silence ffi warnings:
#
# WARN: Unresolved specs during Gem::Specification.reset:
#       ffi (>= 0)
# WARN: Clearing out unresolved specs.
# Please report a bug if this causes problems.
#
# see https://github.com/elasticsearch/logstash/issues/2556 and https://github.com/rubygems/rubygems/issues/1070
#
# this code is from Rubygems v2.1.9 in JRuby 1.7.17. Per tickets this issue should be solved at JRuby >= 1.7.20.

# this method implementation works for Rubygems version 2.1.0 and up, verified up to 2.4.6
if Gem::Version.new(Gem::VERSION) >= Gem::Version.new("2.1.0") && Gem::Version.new(Gem::VERSION) < Gem::Version.new("2.5.0")
  class Gem::Specification
    def self.reset
      @@dirs = nil
      Gem.pre_reset_hooks.each { |hook| hook.call }
      @@all = nil
      @@stubs = nil
      _clear_load_cache
      unresolved = unresolved_deps
      unless unresolved.empty?
        unless (unresolved.size == 1 && unresolved["ffi"])
          w = "W" + "ARN"
          warn "#{w}: Unresolved specs during Gem::Specification.reset:"
          unresolved.values.each do |dep|
            warn "      #{dep}"
          end
          warn "#{w}: Clearing out unresolved specs."
          warn "Please report a bug if this causes problems."
        end
        unresolved.clear
      end
      Gem.post_reset_hooks.each { |hook| hook.call }
    end
  end
end

module LogStash
  module Environment
    extend self

    LOGSTASH_HOME = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", ".."))
    JAR_DIR = ::File.join(LOGSTASH_HOME, "vendor", "jar")
    ELASTICSEARCH_DIR = ::File.join(LOGSTASH_HOME, "vendor", "elasticsearch")
    BUNDLE_DIR = ::File.join(LOGSTASH_HOME, "vendor", "bundle")
    GEMFILE_PATH = ::File.join(LOGSTASH_HOME, "Gemfile")
    BUNDLE_CONFIG_PATH = ::File.join(LOGSTASH_HOME, ".bundle", "config")
    BOOTSTRAP_GEM_PATH = ::File.join(LOGSTASH_HOME, 'build', 'bootstrap')

    LOGSTASH_ENV = (ENV["LS_ENV"] || 'production').to_s.freeze

    # loads currently embedded elasticsearch jars
    # @raise LogStash::EnvironmentError if not running under JRuby or if no jar files are found
    def load_elasticsearch_jars!
      raise(LogStash::EnvironmentError, "JRuby is required") unless jruby?

      require "java"
      jars_path = ::File.join(ELASTICSEARCH_DIR, "**", "*.jar")
      jar_files = Dir.glob(jars_path)

      raise(LogStash::EnvironmentError, "Could not find Elasticsearch jar files under #{ELASTICSEARCH_DIR}") if jar_files.empty?

      jar_files.each do |jar|
        loaded = require jar
        puts("Loaded #{jar}") if $DEBUG && loaded
      end
    end

    def logstash_gem_home
      ::File.join(BUNDLE_DIR, ruby_engine, gem_ruby_version)
    end

    def env
      LOGSTASH_ENV
    end

    def production?
      env.downcase == "production"
    end

    def development?
      env.downcase == "development"
    end

    def test?
      env.downcase == "test"
    end

    def bundler_setup!(options = {})
      options = {:without => [:development]}.merge(options)
      options[:without] = Array(options[:without])
      # make sure we use our own nicely installed bundler and not a rogue, bad, mean, ugly, stupid other bundler. bad bundler, bad bad bundler go away.
      Gem.clear_paths
      Gem.paths = ENV['GEM_HOME'] = ENV['GEM_PATH'] = logstash_gem_home

      # set BUNDLE_GEMFILE ENV before requiring bundler to avoid bundler recurse and load unrelated Gemfile(s)
      ENV["BUNDLE_GEMFILE"] = LogStash::Environment::GEMFILE_PATH

      require "bundler"
      require "logstash/bundler"

      ::Bundler.settings[:path]    = LogStash::Environment::BUNDLE_DIR
      ::Bundler.settings[:without] = options[:without].join(":")
      # in the context of Bundler.setup it looks like this is useless here because Gemfile path can only be specified using
      # the ENV, see https://github.com/bundler/bundler/blob/v1.8.3/lib/bundler/shared_helpers.rb#L103
      ::Bundler.settings[:gemfile] = LogStash::Environment::GEMFILE_PATH

      ::Bundler.reset!
      ::Bundler.setup
    end

    def ruby_bin
      ENV["USE_RUBY"] == "1" ? "ruby" : File.join("vendor", "jruby", "bin", "jruby")
    end

    # @return [String] major.minor ruby version, ex 1.9
    def ruby_abi_version
      RUBY_VERSION[/(\d+\.\d+)(\.\d+)*/, 1]
    end

    # @return [String] the ruby version string bundler uses to craft its gem path
    def gem_ruby_version
      RbConfig::CONFIG["ruby_version"]
    end

    # @return [String] jruby, ruby, rbx, ...
    def ruby_engine
      RUBY_ENGINE
    end

    def jruby?
      @jruby ||= !!(RUBY_PLATFORM == "java")
    end

    def windows?
      Gem.win_platform?
    end

    def vendor_path(path)
      return ::File.join(LOGSTASH_HOME, "vendor", path)
    end

    def plugin_path(path)
      return ::File.join(LOGSTASH_HOME, "lib", "logstash", path)
    end

    def pattern_path(path)
      return ::File.join(LOGSTASH_HOME, "patterns", path)
    end

    def locales_path(path)
      return ::File.join(LOGSTASH_HOME, "locales", path)
    end

    def load_locale!
      require "i18n"
      I18n.enforce_available_locales = true
      I18n.load_path << LogStash::Environment.locales_path("en.yml")
      I18n.reload!
      fail "No locale? This is a bug." if I18n.available_locales.empty?
    end
  end
end

require "logstash/patches"
