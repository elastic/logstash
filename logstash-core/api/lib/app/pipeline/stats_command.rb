# encoding: utf-8
require "app/command"

class LogStash::Api::PipelineStatsCommand < LogStash::Api::Command

  def run
    #return whatever is comming out of the snapshot event, this obvoiusly
    #need to be tailored to the right metrics for this command.
    stats = service.get(:pipeline_stats)
    snapshot = { "events" => {} }
    stats.each_pair do |key, value|
      if key.start_with?("events_")
        field = key.gsub("events_", "")
        snapshot["events"][field] = value
      end
    end
    snapshot
  end

end
