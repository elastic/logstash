
class TrackingMutex < Mutex
  def synchronize(&blk)
    #puts "Enter #{self} @ #{Thread.current} + #{caller[0]}"
    super { blk.call }
    #puts "Exit #{self} @ #{Thread.current} + #{caller[0]}"
  end
end

module LogStash
  class Util
    def self.collapse(hash)
      hash.each do |k, v|
        if v.is_a?(Hash)
          hash.delete(k)
          collapse(v).each do |k2, v2|
            hash["#{k}/#{k2}"] = v2
          end
        elsif v.is_a?(Array)
          # do nothing; ferret can handle this
        elsif not v.is_a?(String)
          hash[k] = v.to_s
        end
      end
      return hash
    end
  end

  class StopWatch
    def initialize
      start
    end # def initialize

    def start
      @start = Time.now
    end # def start

    def duration
      return Time.now - @start
    end # def duration

    def to_s(precision=-1)
      # precision is for numbers, and '.' isn't a number, so pad for '.' if we
      # want >0 precision
      precision += 1 if precision > 0
      return duration.to_s[0 .. precision]
    end # def to_s
  end # class StopWatch

  class SlidingWindowSet
    def initialize(window_size = 100)
      @want = Set.new
      @lock = TrackingMutex.new
      @cv = ConditionVariable.new
      @window_size = window_size
    end

    def <<(val)
      @lock.synchronize do
        if @want.length >= @window_size
          $stderr.puts "sliding window closed (#{@want.length} vs #{@window_size})"
          $stderr.puts "blocking now while sending #{val}"
          @cv.wait(@lock)
          $stderr.puts "sliding window reopend (#{@want.length} vs #{@window_size})"
        end
        @want << val
      end
    end

    def delete(val)
      @lock.synchronize do
        $stderr.puts "Deleting #{val}"
        @want.delete(val)
        if @want.length < @window_size
          @cv.signal
        end
      end
    end

    def include?(val)
      return @want.include?(val)
    end
  end
end


