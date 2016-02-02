# encoding: utf-8
require "app/command"

class LogStash::Api::SystemBasicInfoCommand < LogStash::Api::Command

  def run
    {
      "version"   => LOGSTASH_VERSION,
      "hostname" => hostname,
      "pipeline" => pipeline
    }
  end

  private

  def hostname
    `hostname`.strip
  end


  def pipeline
    { "status" => "ready", "uptime" => 1 }
  end
end
