# encoding: utf-8
require "app/command"

class LogStash::Api::SystemInfoCommand < LogStash::Api::Command

  def run
    plugins_list = available_plugins
    {
      "version"   => LOGSTASH_CORE_VERSION,
      "hostname" => hostname,
      "plugins"   => { "count" => plugins_list.count, "list" => plugins_list.sort }
    }
  end

  private

  def hostname
    `hostname`.strip
  end

  def available_plugins
    all_available_plugins.map do |spec|
      spec.name
    end
  end

  def all_available_plugins
    Gem::Specification.find_all.select do |spec|
      spec.metadata && spec.metadata["logstash_plugin"] == "true"
    end
  end

end
