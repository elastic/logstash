require 'logstash/environment'

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
    # class uses to represent a writer when dead_letter_queue is disabled
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

  class DeadLetterQueueFactory
    java_import org.logstash.common.DeadLetterQueueFactory

    def self.get(pipeline_id)
      if LogStash::SETTINGS.get("dead_letter_queue.enable")
        return DeadLetterQueueWriter.new(
          DeadLetterQueueFactory.getWriter(pipeline_id, LogStash::SETTINGS.get("path.dead_letter_queue"), LogStash::SETTINGS.get('dead_letter_queue.max_bytes')))
      else
        return DeadLetterQueueWriter.new(nil)
      end
    end

    def self.close(pipeline_id)
      DeadLetterQueueFactory.close(pipeline_id)
    end
  end
end end
