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
  end
end
