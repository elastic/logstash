# encoding: utf-8
require "app/command"

class LogStash::Api::StatsEventsCommand < LogStash::Api::Command

  def run
    #return whatever is comming out of the snapshot event, this obvoiusly
    #need to be tailored to the right metrics for this command.
    stats = service.get(:events_stats)
    {
      :in => stats[:base][:events_in].value,
      :out => 0,
      :dropped => stats[:base][:events_filtered].value
    }
  rescue
    {}
  end

end
