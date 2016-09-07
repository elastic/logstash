# encoding: utf-8
require "logstash/namespace"

module LogStash; module Logging; module Util

    class FreqItems

      class Statistics
        attr_reader :mean, :min, :max
        def initialize
          @n = 0
          @mean = 0.0
          @m2 = 0.0
          @min = -1
          @max = 0
        end

        def update(x)
          @n += 1
          delta = x - @mean
          @mean += delta/@n
          @m2 += delta*(x - @mean)

          @max = x if x > @max
          @min = x if x < @min || @min == -1
        end

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

      def top_k(k=10)
        @count.sort_by { |_,v| -v}.first(k)
      end

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
