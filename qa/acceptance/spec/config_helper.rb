# encoding: utf-8
require "json"

module SpecsHelper

  def self.configure(vagrant_boxes)
    setup_config = JSON.parse(File.read(File.join(File.dirname(__FILE__), "..", "..", ".vm_ssh_config")))
    boxes        = vagrant_boxes.inject({}) do |acc, v|
      acc[v.name] = v.type
      acc
    end
    ServiceTester.configure do |config|
      config.servers = []
      config.lookup  = {}
      setup_config.each do |host_info|
        next unless boxes.keys.include?(host_info["host"])
        url = "#{host_info["hostname"]}:#{host_info["port"]}"
        config.servers << url
        config.lookup[url] = {"host" => host_info["host"], "type" => boxes[host_info["host"]] }
      end
    end
  end
end
