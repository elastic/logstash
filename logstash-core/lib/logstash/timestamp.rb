# encoding: utf-8

require "logstash/namespace"

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
