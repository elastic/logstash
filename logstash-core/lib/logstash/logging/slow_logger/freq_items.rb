# encoding: utf-8
require "logstash/namespace"

module LogStash; module Logging; module Util

    class FreqItems

      # This statistics class it provides the necessary methods
      # calculate basic statistics, (min, max, mean and variance) on demand.
      class Statistics

        attr_reader :mean, :min, :max

        def initialize
          @n = 0 # Total number of elements in the series
          @mean = 0.0
          @m2 = 0.0
          @min = -1
          @max = 0
        end

        # Update the current statistics adding a new value to the series
        #
        # @param [Number] x The new element of the series
        def update(x)
          @n += 1 # update the total counter
          # Update the variance related counters
          delta = x - @mean
          @mean += delta/@n
          @m2 += delta*(x - @mean)

          # Update max and min counters
          @max = x if x > @max
          @min = x if x < @min || @min == -1
        end

        # Return variance in the current series of values, the standard deviation would be
        # the square root of this value.
        def variance
          return Float::NAN if @n < 2
          @m2 / (@n - 1)
        end

        def to_hash
          {
            :mean_in_seconds => mean,
            :variance => variance,
            :min_in_seconds => min,
            :max_in_seconds => max
          }
        end
      end

      def initialize
        @count = Hash.new(0)
        @report = Hash.new
      end

      def add(key, value=0)
        @count[key] = @count[key] + 1

        if @report[key].nil?
          @report[key] ||= Hash.new(0)
          @report[key][:statistics] = Statistics.new
        end
        @report[key][:statistics].update(value)
      end

      # Return the top K items based on ocurrences.
      #
      # @param [Number] k The number of items selected. default 10
      def top_k(k=10)
        @count.sort_by { |_,v| -v}.first(k)
      end

      # Return the top K items by time, based on mean seconds and variance.
      #
      # @param [Number] k The number of items selected. default 10
      def top_k_by_time(k=10)
        @report.sort_by do |a|
          -( a[1]["mean_in_seconds"] + a[1]["variance"])
        end.first(k).map { |a| a[0] }
      end

      def report(key)
        @report[key].clone
      end

      def size
        @count.size
      end
    end

end; end; end
