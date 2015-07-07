class InflightEventsReporter
  def self.logger=(logger)
    @logger = logger
  end

  def self.start(input_to_filter, filter_to_output, outputs)
    Thread.new do
      loop do
        sleep 5
        report(input_to_filter, filter_to_output, outputs)
      end
    end
  end

  def self.report(input_to_filter, filter_to_output, outputs)
    report = {
      "input_to_filter" => input_to_filter.size,
      "filter_to_output" => filter_to_output.size,
      "outputs" => []
    }
    outputs.each do |output|
      next unless output.worker_queue && output.worker_queue.size > 0
      report["outputs"] << [output.inspect, output.worker_queue.size]
    end
    @logger.warn ["INFLIGHT_EVENTS_REPORT", Time.now.iso8601, report]
  end
end
