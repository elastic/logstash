require "logstash/errors"

module LogStash
  module Environment
    extend self

    LOGSTASH_HOME = ::File.expand_path(::File.join(::File.dirname(__FILE__), "/../.."))
    JAR_DIR = ::File.join(LOGSTASH_HOME, "/vendor/jar")

    # loads currently embedded elasticsearch jars
    # @raise LogStash::EnvironmentError if not running under JRuby or if no jar files are found
    def load_elasticsearch_jars!
      raise(LogStash::EnvironmentError, "JRuby is required") unless jruby?

      require "java"
      jars_path = ::File.join(JAR_DIR, "/elasticsearch*/lib/*.jar")
      jar_files = Dir.glob(jars_path)

      raise(LogStash::EnvironmentError, "Could not find Elasticsearch jar files under #{JAR_DIR}") if jar_files.empty?

      jar_files.each do |jar|
        loaded = require jar
        puts("Loaded #{jar}") if $DEBUG && loaded
      end
    end

    def jruby?
      RUBY_PLATFORM == "java"
    end

    def vendor_path(path)
      return ::File.join(LOGSTASH_HOME, "vendor", path)
    end

    def plugin_path(path)
      return ::File.join(LOGSTASH_HOME, "lib/logstash", path)
    end

    def pattern_path(path)
      return ::File.join(LOGSTASH_HOME, "patterns", path)
    end

    # @return [String] major.minor ruby version, ex 1.9
    def ruby_minor_version
      RUBY_VERSION[/(\d+\.\d+)(\.\d+)*/, 1]
    end

    # @return [String] jruby, ruby, rbx, ...
    def ruby_engine
      RUBY_ENGINE
    end

    # given a base path, typically what we'd get from --pluginpath search for logstash plugins source dirs.
    # @param base_path [String] an existing dir path which will include logstash/... or lib/logstash/...
    # @return [Array<String>] list of found dirs, [] if none
    def discover_load_paths(base_path)
      [".", "lib"].map{|search_path| ::File.expand_path(::File.join(base_path, search_path))}.select do |path|
        !Dir.glob(::File.join(path, "logstash", "{inputs,codecs,filters,outputs}", "*.rb")).empty?
      end
    end

    # given a base path, typically what we'd get from --pluginpath search for logstash plugins gems dirs
    # in the given path or in the parent path.
    # @param base_path [String] an existing dir path which will include ./vendor/bundle/... or ../vendor/bundle/...
    # @return [Array<String>] list of found dirs, [] if none
    def discover_gem_paths(base_path)
      ["..", "."].map{|search_path| Dir.glob(::File.expand_path(::File.join(base_path, search_path, "vendor", "bundle", ruby_engine, ruby_minor_version)))}.select do |path|
        !path.empty?
      end
    end

  end
end
