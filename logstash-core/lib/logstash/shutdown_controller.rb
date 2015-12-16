# encoding: utf-8

module LogStash
  class ShutdownController

    CHECK_EVERY = 1 # second
    REPORT_EVERY = 5 # checks
    ABORT_AFTER = 3 # stalled reports

    attr_reader :cycle_period, :report_every, :abort_threshold

    def initialize(pipeline, pipeline_thread, cycle_period=CHECK_EVERY, report_every=REPORT_EVERY, abort_threshold=ABORT_AFTER)
      @pipeline = pipeline
      @pipeline_thread = pipeline_thread
      @cycle_period = cycle_period
      @report_every = report_every
      @abort_threshold = abort_threshold
      @reports = []
    end

    def self.unsafe_shutdown=(boolean)
      @unsafe_shutdown = boolean
    end

    def self.unsafe_shutdown?
      @unsafe_shutdown
    end

    def self.logger=(logger)
      @logger = logger
    end

    def self.logger
      @logger ||= Cabin::Channel.get(LogStash)
    end

    def self.start(pipeline, pipeline_thread, cycle_period=CHECK_EVERY, report_every=REPORT_EVERY, abort_threshold=ABORT_AFTER)
      controller = self.new(pipeline, pipeline_thread, cycle_period, report_every, abort_threshold)
      Thread.new(controller) { |controller| controller.start }
    end

    def logger
      self.class.logger
    end

    def start
      sleep(@cycle_period)
      cycle_number = 0
      stalled_count = 0
      Stud.interval(@cycle_period) do
        break unless @pipeline_thread.alive?
        @reports << Report.from_pipeline(@pipeline)
        @reports.delete_at(0) if @reports.size > @report_every # expire old report
        if cycle_number == (@report_every - 1) # it's report time!
          logger.warn(@reports.last.to_hash)

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
        prev_report.inflight_count["total"] <= next_report.inflight_count["total"]
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
  end

  class Report

    attr_reader :inflight_count, :stalling_threads

    def self.from_pipeline(pipeline)
      new(pipeline.inflight_count, pipeline.stalling_threads)
    end

    def initialize(inflight_count, stalling_threads)
      @inflight_count = inflight_count
      @stalling_threads = format_threads_by_plugin(stalling_threads)
    end

    def to_hash
      {
        "INFLIGHT_EVENT_COUNT" => @inflight_count,
        "STALLING_THREADS" => @stalling_threads
      }
    end

    def format_threads_by_plugin(stalling_threads)
      stalled_plugins = {}
      stalling_threads.each do |thr|
        key = (thr.delete("plugin") || "other")
        stalled_plugins[key] ||= []
        stalled_plugins[key] << thr
      end
      stalled_plugins
    end
  end
end
