require "logstash/errors"
require 'logstash/version'

module LogStash
  module Environment
    extend self

    LOGSTASH_HOME = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", ".."))
    JAR_DIR = ::File.join(LOGSTASH_HOME, "vendor", "jar")
    BUNDLE_DIR = ::File.join(LOGSTASH_HOME, "vendor", "bundle")
    PLUGINS_DIR = ::File.join(LOGSTASH_HOME, "vendor", "plugins")
    GEMFILE_PATH = ::File.join(LOGSTASH_HOME, "tools", "Gemfile")

    # loads currently embedded elasticsearch jars
    # @raise LogStash::EnvironmentError if not running under JRuby or if no jar files are found
    def load_elasticsearch_jars!
      raise(LogStash::EnvironmentError, "JRuby is required") unless jruby?

      require "java"
      jars_path = ::File.join(JAR_DIR, "elasticsearch*", "lib", "*.jar")
      jar_files = Dir.glob(jars_path)

      raise(LogStash::EnvironmentError, "Could not find Elasticsearch jar files under #{JAR_DIR}") if jar_files.empty?

      jar_files.each do |jar|
        loaded = require jar
        puts("Loaded #{jar}") if $DEBUG && loaded
      end
    end

    def gem_home
      ::File.join(BUNDLE_DIR, ruby_engine, gem_ruby_version)
    end

    def plugins_home
      # plugins are gems, respect same path structure as core gems_home
      ::File.join(PLUGINS_DIR, ruby_engine, gem_ruby_version)
    end

    def set_gem_paths!
      require ::File.join(BUNDLE_DIR, "bundler", "setup.rb")
      ENV["GEM_PATH"] = plugins_home
      ENV["GEM_HOME"] = plugins_home
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

    def load_logstash_gemspec!
      logstash_spec = Gem::Specification.new do |gem|
        gem.authors       = ["Jordan Sissel", "Pete Fritchman"]
        gem.email         = ["jls@semicomplete.com", "petef@databits.net"]
        gem.description   = %q{scalable log and event management (search, archive, pipeline)}
        gem.summary       = %q{logstash - log and event management}
        gem.homepage      = "http://logstash.net/"
        gem.license       = "Apache License (2.0)"

        gem.name          = "logstash"
        gem.version       = LOGSTASH_VERSION
      end

      Gem::Specification.add_spec logstash_spec
    end

  end
end
