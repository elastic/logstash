# encoding: utf-8
require "json"

module SpecsHelper

  def self.find_selected_boxes(default_boxes=[])
    if ENV.include?('LS_VAGRANT_HOST') then
      default_boxes.include?(ENV['LS_VAGRANT_HOST']) ? ENV['LS_VAGRANT_HOST'] : []
    else
      default_boxes
    end
  end

  def self.configure(vagrant_boxes)
    setup_config = JSON.parse(File.read(File.join(File.dirname(__FILE__), "..", "..", ".vm_ssh_config")))

    ServiceTester.configure do |config|
      config.servers = []
      config.lookup  = {}
      setup_config.each do |host_info|
        next unless vagrant_boxes.include?(host_info["host"])
        url = "#{host_info["hostname"]}:#{host_info["port"]}"
        config.servers << url
        config.lookup[url] = host_info["host"]
      end
    end
  end
end
