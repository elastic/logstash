# encoding: utf-8
require "java"

module LogStash; module Util
  class WrappedConcurrentLinkedQueue
    java_import java.util.concurrent.ConcurrentLinkedQueue
    java_import java.util.concurrent.TimeUnit

    def initialize
      @queue = java.util.concurrent.ConcurrentLinkedQueue.new
    end

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [Object] Object to add to the queue
    def push(obj)
      @queue.offer(obj)
    end
    alias_method(:<<, :push)
    alias_method(:offer, :push)

    def pop
      @queue.poll
    end
    alias_method(:take, :pop)
    alias_method(:poll, :pop)
  end # class WrappedSynchronousQueue
end end # module LogStash; module Util
