# encoding: utf-8

require "logstash/namespace"

# Force loading the RubyUtil to ensure its loaded before the Timestamp class is set up in Ruby since
# Timestamp depends on Ruby classes that are dynamically set up by Java code.
java_import org.logstash.RubyUtil

module LogStash

  class Timestamp
    include Comparable

    # TODO (colin) implement in Java
    def <=>(other)
      self.time <=> other.time
    end

    def eql?(other)
      self.== other
    end

    # TODO (colin) implement in Java
    def +(other)
      self.time + other
    end

    # TODO (colin) implement in Java
    def -(value)
      self.time - (value.is_a?(Timestamp) ? value.time : value)
    end

  end
end
