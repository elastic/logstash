# encoding: utf-8

require "thread"

Thread.abort_on_exception = true

class Stats

  REFRESH_COUNT = 100

  attr_accessor :stats

  def initialize
    @stats = []
  end
  # below stats counter and output reader threads are sharing state using
  # the @stats_lock mutex, @stats_count and @stats. this is a bit messy and should be
  # refactored into a proper class eventually

  def detach_stats_counter
    Thread.new do
      loop do
        start = @stats_lock.synchronize{@stats_count}
        sleep(1)
        @stats_lock.synchronize{@stats << (@stats_count - start)}
      end
    end
  end

  # detach_output_reader spawns a thread that will fill in the @stats instance var with tps samples for every seconds
  # @stats access is synchronized using the @stats_lock mutex but can be safely used
  # once the output reader thread is completed.
  def detach_output_reader(io, regex)
    Thread.new(io, regex) do |io, regex|
      i = 0
      @stats = []
      @stats_count = 0
      @stats_lock = Mutex.new
      t = detach_stats_counter

      expect_output(io, regex) do
        i += 1
        # avoid mutex synchronize on every loop cycle, using REFRESH_COUNT = 100 results in
        # much lower mutex overhead and still provides a good resolution since we are typically
        # have 2000..100000 tps
        @stats_lock.synchronize{@stats_count = i} if (i % REFRESH_COUNT) == 0
      end

      @stats_lock.synchronize{t.kill}
    end
  end

    def expect_output(io, regex)
    io.each_line do |line|
      puts("received: #{line}") if @debug
      yield if block_given?
      break if line =~ regex
    end
  end

end
