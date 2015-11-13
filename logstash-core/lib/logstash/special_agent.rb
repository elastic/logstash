# encoding: utf-8
require "logstash/agent"

class LogStash::SpecialAgent < LogStash::Agent
  def fetch_config(settings)
    Net::HTTP.get(settings["remote.url"])
  end
end
