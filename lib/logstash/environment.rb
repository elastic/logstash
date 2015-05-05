require "logstash/errors"
require "logstash/version"

module LogStash
  module Environment
    extend self

    # rehydrate the bootstrap environment if the startup was not done by executing bootstrap.rb
    # and we are in the context of the logstash package
    if !LogStash::Environment.const_defined?("LOGSTASH_HOME") &&  !ENV["LOGSTASH_HOME"].to_s.empty?
      $LOAD_PATH << ::File.join(ENV["LOGSTASH_HOME"], "lib")
      require "bootstrap/environment"
    end

    LOGSTASH_CORE = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", ".."))
    LOGSTASH_ENV = (ENV["LS_ENV"] || 'production').to_s.freeze

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

    def runtime_jars_root(dir_name, package)
      ::File.join(dir_name, package, "runtime-jars")
    end

    def test_jars_root(dir_name, package)
      ::File.join(dir_name, package, "test-jars")
    end

    def load_runtime_jars!(dir_name="vendor", package="jar-dependencies")
      load_jars!(::File.join(runtime_jars_root(dir_name, package), "*.jar"))
    end

    def load_test_jars!(dir_name="vendor", package="jar-dependencies")
      load_jars!(::File.join(test_jars_root(dir_name, package), "*.jar"))
    end

    def load_jars!(pattern)
      raise(LogStash::EnvironmentError, I18n.t("logstash.environment.jruby-required")) unless LogStash::Environment.jruby?

      jar_files = find_jars(pattern)
      require_jars! jar_files
    end

    def find_jars(pattern)
      require 'java'
      jar_files = Dir.glob(pattern)
      raise(LogStash::EnvironmentError, I18n.t("logstash.environment.missing-jars", :pattern => pattern)) if jar_files.empty?
      jar_files
    end

    def require_jars!(files)
      files.each do |jar_file|
        loaded = require jar_file
        puts("Loaded #{jar_file}") if $DEBUG && loaded
      end
    end

    def ruby_bin
      ENV["USE_RUBY"] == "1" ? "ruby" : File.join("vendor", "jruby", "bin", "jruby")
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

    def pattern_path(path)
      return ::File.join(LOGSTASH_HOME, "patterns", path)
    end

    def locales_path(path)
      return ::File.join(LOGSTASH_CORE, "locales", path)
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
