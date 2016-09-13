# encoding: utf-8
require "logstash/errors"
require "logstash/java_integration"
require "logstash/config/cpu_core_strategy"
require "logstash/settings"
require "socket"
require "stud/temporary"

module LogStash
  # In the event that we're requiring this file without bootstrap/environment.rb
  if !defined?(LogStash::Environment::LOGSTASH_HOME)
    module Environment
      LOGSTASH_HOME = Stud::Temporary.directory("logstash-home")
      Dir.mkdir(::File.join(LOGSTASH_HOME, "data"))
    end
  end

  [
            Setting::String.new("node.name", Socket.gethostname),
            Setting::String.new("path.config", nil, false),
 Setting::WritableDirectory.new("path.data", ::File.join(LogStash::Environment::LOGSTASH_HOME, "data")),
            Setting::String.new("config.string", nil, false),
           Setting::Boolean.new("config.test_and_exit", false),
           Setting::Boolean.new("config.reload.automatic", false),
           Setting::Numeric.new("config.reload.interval", 3), # in seconds
           Setting::Boolean.new("metric.collect", true) {|v| v == true }, # metric collection cannot be disabled
            Setting::String.new("pipeline.id", "main"),
   Setting::PositiveInteger.new("pipeline.workers", LogStash::Config::CpuCoreStrategy.maximum),
   Setting::PositiveInteger.new("pipeline.output.workers", 1),
   Setting::PositiveInteger.new("pipeline.batch.size", 125),
           Setting::Numeric.new("pipeline.batch.delay", 5), # in milliseconds
           Setting::Boolean.new("pipeline.unsafe_shutdown", false),
                    Setting.new("path.plugins", Array, []),
            Setting::String.new("interactive", nil, false),
           Setting::Boolean.new("config.debug", false),
            Setting::String.new("log.level", "info", true, ["fatal", "error", "warn", "debug", "info", "trace"]),
           Setting::Boolean.new("version", false),
           Setting::Boolean.new("help", false),
            Setting::String.new("log.format", "plain", true, ["json", "plain"]),
            Setting::String.new("http.host", "127.0.0.1"),
            Setting::PortRange.new("http.port", 9600..9700),
            Setting::String.new("http.environment", "production"),
  ].each {|setting| SETTINGS.register(setting) }

  module Environment
    extend self

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
      ::Gem.win_platform?
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

    # add path for bare/ungemified plugins lookups. the path must be the base path that will include
    # the dir structure 'logstash/TYPE/NAME.rb' where TYPE is 'inputs' 'filters', 'outputs' or 'codecs'
    # and NAME is the name of the plugin
    # @param path [String] plugins path to add
    def add_plugin_path(path)
      $LOAD_PATH << path
    end
  end
end

require "logstash/patches"
