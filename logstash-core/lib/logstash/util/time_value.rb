# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

module LogStash
  module Util
    class TimeValue
      def initialize(duration, time_unit)
        @duration = duration
        @time_unit = time_unit
      end

      def self.from_value(value)
        case value
        when TimeValue
          return value # immutable
        when ::String
          normalized = value.downcase.strip
          if normalized.end_with?("nanos")
            TimeValue.new(parse(normalized, 5), :nanosecond)
          elsif normalized.end_with?("micros")
            TimeValue.new(parse(normalized, 6), :microsecond)
          elsif normalized.end_with?("ms")
            TimeValue.new(parse(normalized, 2), :millisecond)
          elsif normalized.end_with?("s")
            TimeValue.new(parse(normalized, 1), :second)
          elsif normalized.end_with?("m")
            TimeValue.new(parse(normalized, 1), :minute)
          elsif normalized.end_with?("h")
            TimeValue.new(parse(normalized, 1), :hour)
          elsif normalized.end_with?("d")
            TimeValue.new(parse(normalized, 1), :day)
          elsif normalized =~ /^-0*1/
            TimeValue.new(-1, :nanosecond)
          else
            raise ArgumentError.new("invalid time unit: \"#{value}\"")
          end
        else
          raise ArgumentError.new("value is not a string: #{value} [#{value.class}]")
        end
      end

      def to_nanos
        case @time_unit
        when :day
          86400000000000 * @duration
        when :hour
          3600000000000 * @duration
        when :minute
          60000000000 * @duration
        when :second
          1000000000 * @duration
        when :millisecond
          1000000 * @duration
        when :microsecond
          1000 * @duration
        when :nanosecond
          @duration
        end
      end

      def to_seconds
        self.to_nanos / 1_000_000_000.0
      end

      def ==(other)
        (self.duration == other.duration && self.time_unit == other.time_unit) || self.to_nanos == other.to_nanos
      end

      def self.parse(value, suffix)
        Integer(value[0..(value.size - suffix - 1)].strip)
      end

      private_class_method :parse
      attr_reader :duration
      attr_reader :time_unit
    end
  end
end
