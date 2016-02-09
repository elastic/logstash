# encoding: utf-8
require "app/command"
require "logstash/util/duration_formatter"

class LogStash::Api::SystemBasicInfoCommand < LogStash::Api::Command

  def run
    {
      "hostname" => hostname,
      "version" => {
        "number" => LOGSTASH_VERSION,
      }
    }
  end
end
