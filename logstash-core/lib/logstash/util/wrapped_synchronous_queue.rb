# encoding: utf-8

module LogStash; module Util
  class WrappedSynchronousQueue
    java_import java.util.concurrent.SynchronousQueue
    java_import java.util.concurrent.TimeUnit

    def initialize()
      @queue = java.util.concurrent.SynchronousQueue.new()
    end

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [Object] Object to add to the queue
    def push(obj)
      @queue.put(obj)
    end
    alias_method(:<<, :push)

    # Offer an object to the queue, wait for the specified amout of time.
    # If adding to the queue was successfull it wil return true, false otherwise.
    #
    # @param [Object] Object to add to the queue
    # @param [Integer] Time in milliseconds to wait before giving up
    # @return [Boolean] True if adding was successfull if not it return false
    def offer(obj, timeout_ms)
      @queue.offer(obj, timeout_ms, TimeUnit::MILLISECONDS)
    end

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
