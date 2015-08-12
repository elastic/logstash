class ShutdownController

  REPORT_CYCLE = 5 # seconds
  DUMP_PATH = "/tmp"
  REPORTS = []
  NUM_REPORTS = 3

  def self.force_exit_on_stall=(boolean)
    @force_exit_on_stall = boolean
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.start(input_to_filter, filter_to_output, outputs)
    Thread.new do
      loop do
        sleep REPORT_CYCLE
        REPORTS << collect(input_to_filter, filter_to_output, outputs)
        REPORTS.delete_at(0) if REPORTS.size > NUM_REPORTS # expire old report
        report(REPORTS.last)
        if @force_exit_on_stall && stalled?
          @logger.fatal("Stalled pipeline detected. Forcefully quitting logstash..")
          dump_queue(input_to_filter)
          force_exit()
        end
      end
    end
  end

  def self.dump_queue(queue)
    file_dump_path = File.join(DUMP_PATH, "dump.#{Time.now.strftime("%Y%m%d%H%M%S")}")
    dump = []
    until queue.empty? do
      event = queue.pop(true) rescue ThreadError # non-block pop
      next unless event.is_a?(LogStash::Event)
      dump << event.to_json
    end
    IO.write(file_dump_path, dump.join("\n")) if dump.any?
    @logger.warn("Dumped #{dump.size} events to \"#{file_dump_path}\"")
  end

  def self.force_exit
    exit(-1)
  end

  def self.collect(input_to_filter, filter_to_output, outputs)
    data = {
      "input_to_filter" => input_to_filter.size,
      "filter_to_output" => filter_to_output.size,
      "outputs" => []
    }
    outputs.each do |output|
      next unless output.worker_queue && output.worker_queue.size > 0
      data["outputs"] << [output.inspect, output.worker_queue.size]
    end

    data["total"] = data["input_to_filter"] + data["filter_to_output"] +
                    data["outputs"].map(&:last).inject(0, :+)
    data
  end

  def self.report(report)
    @logger.warn ["INFLIGHT_EVENTS_REPORT", Time.now.iso8601, report]
  end

  def self.stalled?
    return false unless REPORTS.size == NUM_REPORTS
    # check if inflight count is either constant or increasing
    REPORTS.each_cons(2).all? do |prev_report, next_report|
      prev_report["total"] <= next_report["total"]
    end
  end
end
