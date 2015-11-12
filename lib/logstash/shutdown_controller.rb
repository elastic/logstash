# encoding: utf-8
require 'pp'

module LogStash
  class ShutdownController

    CHECK_EVERY = 1 # second
    REPORT_EVERY = 5 # checks
    ABORT_AFTER = 3 # stalled reports
    REPORTS = []

    def self.force_shutdown=(boolean)
      @force_shutdown = boolean
    end

    def self.force_shutdown?
      @force_shutdown
    end

    def logger=(logger)
      @logger = logger
    end

    def logger
      @logger ||= Cabin::Channel.get(LogStash)
    end

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def start(cycle_period=CHECK_EVERY, report_every=REPORT_EVERY, abort_threshold=ABORT_AFTER)
      @thread ||= Thread.new do
        sleep(cycle_period)
        cycle_number = 0
        stalled_count = 0
        Stud.interval(cycle_period) do
          REPORTS << generate_report(@pipeline)
          REPORTS.delete_at(0) if REPORTS.size > REPORT_EVERY # expire old report
          if cycle_number == (REPORT_EVERY - 1) # it's report time!
            logger.warn(REPORTS.last)

            if stalled?
              logger.error("The shutdown process appears to be stalled due to busy or blocked plugins. Check the logs for more information.") if stalled_count == 0
              stalled_count += 1

              if self.class.force_shutdown? && abort_threshold == stalled_count
                logger.fatal("Forcefully quitting logstash..")
                @pipeline.force_exit()
                break
              end
            else
              stalled_count = 0
            end
          end
          cycle_number = (cycle_number + 1) % report_every
        end
      end
    end

    def stop!
      @thread.terminate if @thread.is_a?(Thread)
      @thread = nil
    end

    def stalled?
      return false unless REPORTS.size == REPORT_EVERY
      # is stalled if inflight count is either constant or increasing
      stalled_event_count = REPORTS.each_cons(2).all? do |prev_report, next_report|
        prev_report["INFLIGHT_EVENT_COUNT"]["total"] <= next_report["INFLIGHT_EVENT_COUNT"]["total"]
      end
      if stalled_event_count
        REPORTS.each_cons(2).all? do |prev_report, next_report|
          prev_report["STALLING_THREADS"] == next_report["STALLING_THREADS"]
        end
      else
        false
      end
    end

    def generate_report(pipeline)
      {
        "INFLIGHT_EVENT_COUNT" => pipeline.inflight_count,
        "STALLING_THREADS" => format_threads_by_plugin(pipeline.stalling_threads)
      }
    end

    def format_threads_by_plugin(threads)
      stalled_plugins = {}
      threads.each do |thr|
        key = (thr.delete("plugin") || "other")
        stalled_plugins[key] ||= []
        stalled_plugins[key] << thr
      end
      stalled_plugins
    end
  end
end
