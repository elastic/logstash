# encoding: utf-8
require "concurrent/atomic/atomic_fixnum"
require "concurrent/atomic/atomic_boolean"

module LogStash
  class ShutdownWatcher
    include LogStash::Util::Loggable

    CHECK_EVERY = 1 # second
    REPORT_EVERY = 5 # checks
    ABORT_AFTER = 3 # stalled reports

    attr_reader :cycle_period, :report_every, :abort_threshold

    def initialize(pipeline, cycle_period=CHECK_EVERY, report_every=REPORT_EVERY, abort_threshold=ABORT_AFTER)
      @pipeline = pipeline
      @cycle_period = cycle_period
      @report_every = report_every
      @abort_threshold = abort_threshold
      @reports = []
      @attempts_count = Concurrent::AtomicFixnum.new(0)
      @running = Concurrent::AtomicBoolean.new(false)
    end

    def self.unsafe_shutdown=(boolean)
      @unsafe_shutdown = boolean
    end

    def self.unsafe_shutdown?
      @unsafe_shutdown
    end

    def self.start(pipeline, cycle_period=CHECK_EVERY, report_every=REPORT_EVERY, abort_threshold=ABORT_AFTER)
      controller = self.new(pipeline, cycle_period, report_every, abort_threshold)
      Thread.new(controller) { |controller| controller.start }
    end

    def logger
      self.class.logger
    end

    def attempts_count
      @attempts_count.value
    end

    def stop!
      @running.make_false
    end

    def stopped?
      @running.false?
    end

    def start
      sleep(@cycle_period)
      cycle_number = 0
      stalled_count = 0
      running!
      Stud.interval(@cycle_period) do
        @attempts_count.increment
        break if stopped?
        break unless @pipeline.thread.alive?
        @reports << pipeline_report_snapshot
        @reports.delete_at(0) if @reports.size > @report_every # expire old report
        if cycle_number == (@report_every - 1) # it's report time!
          logger.warn(@reports.last.to_s)

          if shutdown_stalled?
            logger.error("The shutdown process appears to be stalled due to busy or blocked plugins. Check the logs for more information.") if stalled_count == 0
            stalled_count += 1

            if self.class.unsafe_shutdown? && @abort_threshold == stalled_count
              logger.fatal("Forcefully quitting logstash..")
              force_exit()
              break
            end
          else
            stalled_count = 0
          end
        end
        cycle_number = (cycle_number + 1) % @report_every
      end
    ensure
      stop!
    end

    def pipeline_report_snapshot
      @pipeline.reporter.snapshot
    end

    # A pipeline shutdown is stalled if
    # * at least REPORT_EVERY reports have been created
    # * the inflight event count is in monotonically increasing
    # * there are worker threads running which aren't blocked on SizedQueue pop/push
    # * the stalled thread list is constant in the previous REPORT_EVERY reports
    def shutdown_stalled?
      return false unless @reports.size == @report_every #
      # is stalled if inflight count is either constant or increasing
      stalled_event_count = @reports.each_cons(2).all? do |prev_report, next_report|
        prev_report.inflight_count <= next_report.inflight_count
      end
      if stalled_event_count
        @reports.each_cons(2).all? do |prev_report, next_report|
          prev_report.stalling_threads == next_report.stalling_threads
        end
      else
        false
      end
    end

    def force_exit
      exit(-1)
    end

    private
    def running!
      @running.make_true
    end
  end
end
