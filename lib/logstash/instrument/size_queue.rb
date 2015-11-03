# encoding: utf-8
require "forwardable"

module LogStash module Instrument
  class SizeQueue
    extend Forwardable

    def_delegators :@size_queue, :clear, :size, :empty?, :length, :num_waiting
    attr_reader :metric

    def initialize(size_queue, metric)
      @size_queue = size_queue
      @metric = metric
    end

    def push(item)
      @size_queue.push(item)
      metric.increment(:in)
    end

    alias_method :<<, :push
    alias_method :enq, :push

    def pop(non_block = false)
      @size_queue.pop(non_block)
      metric.increment(:out)
    end

    alias_method :deq, :pop
    alias_method :shift, :pop
  end
end; end
