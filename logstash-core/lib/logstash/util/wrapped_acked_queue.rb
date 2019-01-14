# encoding: utf-8

require "concurrent"
# This is an adapted copy of the wrapped_synchronous_queue file
# ideally this should be moved to Java/JRuby

module LogStash; module Util
  # Some specialized constructors. The calling code *does* need to know what kind it creates but
  # not the internal implementation e.g. LogStash::AckedMemoryQueue etc.
  # Note the use of allocate - this is what new does before it calls initialize.
  # Note that the new method has been made private this is because there is no
  # default queue implementation.
  # It would be expensive to create a persistent queue in the new method
  # to then throw it away in favor of a memory based one directly after.
  # Especially in terms of (mmap) memory allocation and proper close sequencing.

  class WrappedAckedQueue
    class QueueClosedError < ::StandardError; end
    class NotImplementedError < ::StandardError; end

    def self.create_file_based(path, capacity, max_events, checkpoint_max_writes, checkpoint_max_acks, checkpoint_max_interval, max_bytes)
      self.allocate.with_queue(
        LogStash::AckedQueue.new(path, capacity, max_events, checkpoint_max_writes, checkpoint_max_acks, checkpoint_max_interval, max_bytes)
      )
    end

    private_class_method :new

    attr_reader :queue

    def with_queue(queue)
      @queue = queue
      @queue.open
      @closed = java.util.concurrent.atomic.AtomicBoolean.new(false)
      self
    end

    def closed?
      @closed.get
    end

    # Push an object to the queue if the queue is full
    # it will block until the object can be added to the queue.
    #
    # @param [Object] Object to add to the queue
    def push(obj)
      check_closed("write")
      @queue.write(obj)
    end
    alias_method(:<<, :push)

    def read_batch(size, wait)
      check_closed("read a batch")
      @queue.read_batch(size, wait)
    end

    def write_client
      LogStash::AckedWriteClient.create(@queue, @closed)
    end

    def read_client()
      LogStash::AckedReadClient.create(self)
    end

    def check_closed(action)
      if @closed.get
        raise QueueClosedError.new("Attempted to #{action} on a closed AckedQueue")
      end
    end

    def is_empty?
      @queue.is_empty?
    end

    def close
      @queue.close
      @closed.set(true)
    end
  end
end end
