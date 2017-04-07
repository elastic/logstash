
module LogStash; module Util
  class PluginDeadLetterQueueWriter

    attr_reader :plugin_id, :plugin_type, :inner_writer

    def initialize(inner_writer, plugin_id, plugin_type)
      @plugin_id = plugin_id
      @plugin_type = plugin_type
      @inner_writer = inner_writer
    end

    def write(logstash_event, reason)
      if @inner_writer && @inner_writer.is_open
        @inner_writer.writeEntry(logstash_event.to_java, @plugin_type, @plugin_id, reason)
      end
    end

    def close
      if @inner_writer && @inner_writer.is_open
        @inner_writer.close
      end
    end
  end

  class DummyDeadLetterQueueWriter
    def initialize
    end

    def write(logstash_event, reason)
      # noop
    end

    def is_open
      false
    end

    def close
      # noop
    end
  end
end end
