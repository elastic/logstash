# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/json"

module LogStash; module Logging; class JSON
  def initialize(io)
    raise ArgumentError, "Expected IO, got #{io.class.name}" unless io.is_a?(IO)

    @io = io
    @lock = Mutex.new
  end

  def <<(obj)
    serialized = LogStash::Json.dump(obj)
    @lock.synchronize do
      @io.puts(serialized)
      @io.flush
    end
  end
end; end; end
