# encoding: utf-8

module LogStash; module Util
  class WrappedSynchronousQueue
    java_import java.util.concurrent.ArrayBlockingQueue
    java_import java.util.concurrent.TimeUnit
    java_import org.logstash.common.LsQueueUtils

    def initialize (size)
      @queue = ArrayBlockingQueue.new(size)
    end

    attr_reader :queue

    def write_client
      WriteClient.new(@queue)
    end

    def read_client
      LogStash::MemoryReadClient.new(@queue, 125, 50)
    end

    def close
      # ignore
    end

    class WriteClient
      def initialize(queue)
        @queue = queue
      end

      def push(event)
        @queue.put(event)
      end
      alias_method(:<<, :push)

      def push_batch(batch)
        LsQueueUtils.addAll(@queue, batch)
      end
    end
  end
end end
