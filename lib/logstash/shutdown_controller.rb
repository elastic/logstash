# encoding: utf-8
module LogStash
  class ShutdownController

    REPORT_CYCLE = 5 # seconds
    REPORTS = []
    NUM_REPORTS = 3

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

    def start(cycle=REPORT_CYCLE)
      @thread ||= Thread.new do
        Stud.interval(cycle) do
          REPORTS << @pipeline.inflight_count
          REPORTS.delete_at(0) if REPORTS.size > NUM_REPORTS # expire old report
          report(REPORTS.last)
          if self.class.force_shutdown? && stalled?
            logger.fatal("Stalled pipeline detected. Forcefully quitting logstash..")
            @pipeline.dump.each {|e| DeadLetterPostOffice.post(e) }
            @pipeline.force_exit()
            break
          end
        end
      end
    end

    def stop!
      @thread.terminate if @thread.is_a?(Thread)
      @thread = nil
    end

    def report(report)
      logger.warn ["INFLIGHT_EVENTS_REPORT", Time.now.iso8601, report]
    end

    def stalled?
      return false unless REPORTS.size == NUM_REPORTS
      # is stalled if inflight count is either constant or increasing
      REPORTS.each_cons(2).all? do |prev_report, next_report|
        prev_report["total"] <= next_report["total"]
      end
    end
  end
end
