# encoding: utf-8
require "app/command"

class LogStash::Api::StatsEventsCommand < LogStash::Api::Command

  def run
    #return whatever is comming out of the snapshot event, this obvoiusly
    #need to be tailored to the right metrics for this command.
    stats = service.get(:events_stats)
    {
      :in => stats[:stats][:events][:in].value,
      :filtered => stats[:stats][:events][:filtered].value,
      :out => stats[:stats][:events][:out].value
    }
  rescue
    {}
  end

end
