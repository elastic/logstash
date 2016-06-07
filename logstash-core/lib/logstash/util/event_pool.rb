require "thread"
require "logstash/event"
require "logstash/util/wrapped_concurrent_linked_queue"

module LogStash; module Util
  class EventPool
    def initialize(max_size)
      @max_size = max_size
      @queue = LogStash::Util::WrappedConcurrentLinkedQueue.new
    end

    # TODO: Handle Max Size to prevent Exceptions
    def obtain(data)
      event = @queue.pop
      if event.nil?
        event = Event.new(data)
      else
        event.reset(data)
      end

      event
    end

    def release(event)
      @queue.push(event)
    end
  end
end end
