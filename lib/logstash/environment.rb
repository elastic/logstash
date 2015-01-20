require "logstash/errors"
require 'logstash/version'

module LogStash
  module Environment
    extend self

    LOGSTASH_HOME = ::File.expand_path(::File.join(::File.dirname(__FILE__), "..", ".."))
    JAR_DIR = ::File.join(LOGSTASH_HOME, "vendor", "jar")
    ELASTICSEARCH_DIR = ::File.join(LOGSTASH_HOME, "vendor", "elasticsearch")
    BUNDLE_DIR = ::File.join(LOGSTASH_HOME, "vendor", "bundle")
    GEMFILE_PATH = ::File.join(LOGSTASH_HOME, "tools", "Gemfile")
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

    # set GEM_PATH for logstash runtime
    # GEM_PATH should include the logstash gems, the plugin gems and the bootstrap gems.
    # the bootstrap gems are required specificly for bundler which is a runtime dependency
    # of some plugins dependedant gems.
    def set_gem_paths!
      ENV["GEM_HOME"] = ENV["GEM_PATH"] = logstash_gem_home
      ENV["BUNDLE_GEMFILE"] = GEMFILE_PATH unless ENV['BUNDLE_GEMFILE']

      require 'bundler'
      require 'logstash/bundler_patch'

      Bundler.setup

      # Bundler.setup will wipe the existing $LOAD_PATH.
      # Since we are using gems not declared in the gemfile we need to
      # recalculate the $LOAD_PATH with all the available gems.
      load_paths = Gem::Specification
        .collect(&:load_paths)
        .flatten
        .reject { |path| $LOAD_PATH.include?(path) }

      $LOAD_PATH.unshift(*load_paths)
    end

    def bundler_install_command(gem_file, gem_path)
      # for now avoid multiple jobs, ex.: --jobs 4
      # it produces erratic exceptions and hangs (with Bundler 1.7.9)
      options = [
        "install",
        "--gemfile=#{gem_file}",
        "--path",
        gem_path,
      ]

      # We don't install development gem from the gemfile.
      # If you add a gem with `git` or the `github` option bundler will mark
      # them as development and he will not install them.
      # To install them you need to do LOGSTASH_ENV=development rake gems:vendor
      options << "--without=development" unless LogStash::Environment.development?
      options
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

    def load_locale!
      require "i18n"
      I18n.enforce_available_locales = true
      I18n.load_path << LogStash::Environment.locales_path("en.yml")
      I18n.reload!
      fail "No locale? This is a bug." if I18n.available_locales.empty?
    end
  end
end
