# encoding: utf-8
require "app/command"
require "logstash/util/duration_formatter"

class LogStash::Api::SystemBasicInfoCommand < LogStash::Api::Command

  attr_reader :agent

  def run
    @agent = service.agent
    {
      "version"   => LOGSTASH_VERSION,
      "hostname" => @agent.node_name,
    }
  end

  private

  def pipelines
    pipes = {}
    @agent.pipelines.each do |key, pipeline|
      pipeline_status = pipeline.running? ? "running" : "stop"
      pipes[key] = {
        "status" => pipeline_status,
        "uptime_in_millis" => pipeline.uptime,
        "uptime" => LogStash::Util::DurationFormatter.human_format(pipeline.uptime)
      }
    end
    pipes
  end
end
