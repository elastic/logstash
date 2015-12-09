# encoding: utf-8
require "app/command"

class LogStash::Api::SystemInfoCommand < LogStash::Api::Command

  def run
    report = { "version"   => "1.0.0",
               "host_name" => "foobar",
               "plugins"   => { "count" => 10, "list" => [] }
    }
    report
  end

  private

  def type
    ["input", "output", "filter"][rand(3)]
  end

  def name
    ["elasticsearch", "json", "yaml", "translate"][rand(4)]
  end
end
