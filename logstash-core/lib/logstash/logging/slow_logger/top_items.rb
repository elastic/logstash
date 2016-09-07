# encoding: utf-8
require "logstash/namespace"
require "set"
require 'thread'

module LogStash; module Logging; module Util

  class Operation

    attr_reader :threshold, :time

    def initialize(threshold, time)
      @threshold = threshold
      @time = time
    end

    def <=>(other)
      if threshold != other.threshold
        return threshold <=> other.threshold
      end
      return -1 if time > other.time
      return  0 if time == other.time
      return  1 if time < other.time
    end

    def to_s
      "#{threshold}:#{time}"
    end
  end

  class TopItems

    SIZE = 10.freeze

    ##
    # All elements that are added to a SortedSet must respond to the <=> method for comparison.
    ##
    def initialize
      @set = SortedSet.new
      @sem = Mutex.new
    end

    def add(key, value)
      item = Operation.new(key, value)
      @sem.synchronize do
        if @set.size > SIZE-1
          @set = SortedSet.new(@set.take(SIZE-1))
        end
        @set.add(item)
      end
    end

    def top_k(n=SIZE)
      @sem.synchronize do
        @set.take(n)
      end
    end

    def size
      @set.size
    end

    def to_s
      @set.inspect
    end

  end

end; end; end
