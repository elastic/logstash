# encoding: utf-8
java_import "java.util.concurrent.ConcurrentLinkedQueue"

module LogStash module Instrument
  class ConcurrentLinkedQueue
    def initialize
      @queue = java.util.concurrent.ConcurrentLinkedQueue.new
    end

    def offer(item)
      @queue.offer(item)
    end

    def poll
      @queue.poll
    end
  end
end; end
