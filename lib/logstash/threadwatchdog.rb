require "logstash/namespace"
require "logstash/logging"

class LogStash::ThreadWatchdog
  attr_accessor :logger
  attr_accessor :threads

  class TimeoutError < StandardError; end

  public
  def initialize(threads, watchdog_timeout=2)
    @threads = threads
    @watchdog_timeout = watchdog_timeout
  end # def initialize

  public
  def watch
    while sleep(@watchdog_timeout / 2)
      cutoff = Time.now - @watchdog_timeout
      @threads.each do |t|
        watchdog = t[:watchdog]
        if watchdog and watchdog <= cutoff
          @logger.fatal("thread watchdog timeout",
                        :thread => t,
                        :backtrace => t.backtrace,
                        :thread_watchdog => t[:watchdog],
                        :cutoff => @watchdog_timeout,
                        :state => t[:watchdog_state])
          raise TimeoutError, "watchdog timeout"
        end
      end
    end
  end # def watch
end # class LogStash::ThreadWatchdog
