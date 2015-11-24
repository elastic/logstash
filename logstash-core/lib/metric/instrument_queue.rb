# encoding: utf-8
require "forwardable"

module LogStash
  module Metric
    class InstrumentQueue
      extend Forwardable
      attr_reader :collector

      def_delegators :@queue, :size, :max, :max=, :num_waiting, :clear

      def initialize(queue, collector)
        @queue = queue
        @collector = collector
      end

      def push(item)
        @queue << item
      end
      alias_method :<<, :push
      alias_method :enq, :push

      def pop
        @queue.pop
      end
      alias_method :deq, :pop
    end
  end
end
