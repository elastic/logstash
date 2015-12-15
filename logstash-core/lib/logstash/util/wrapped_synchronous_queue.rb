# encoding: utf-8

module LogStash; module Util
  class WrappedSynchronousQueue
    java_import java.util.concurrent.SynchronousQueue
    java_import java.util.concurrent.TimeUnit

    def initialize()
      @queue = java.util.concurrent.SynchronousQueue.new()
    end

    def push(obj)
      @queue.put(obj)
    end
    alias_method(:<<, :push)

    # Blocking
    def take
      @queue.take()
    end

    # Block for X millis
    def poll(millis)
      @queue.poll(millis, TimeUnit::MILLISECONDS)
    end
  end
end end