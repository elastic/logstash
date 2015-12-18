# encoding: utf-8
require "app/command"

class LogStash::Api::PipelineStatsCommand < LogStash::Api::Command

  def run
    #return whatever is comming out of the snapshot event, this obvoiusly
    #need to be tailored to the right metrics for this command.
    stats = service.get(:pipeline_stats)
    { "events" => { "in" => stats[:base][:events_in].value, "filtered" => stats[:base][:events_filtered].value } }
  rescue
    { "events" => {} }
  end

end
