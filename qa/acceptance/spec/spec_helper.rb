# encoding: utf-8
require 'runner-tool'
require_relative '../../rspec/helpers'
require_relative '../../rspec/matchers'
require_relative 'config_helper'
require_relative "../../platform_config"

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
$LOAD_PATH.unshift File.join(ROOT, 'logstash-core/lib')

RunnerTool.configure

RSpec.configure do |c|
  c.include ServiceTester
end

platform = ENV['LS_TEST_PLATFORM'] || 'all'

config   = PlatformConfig.new
default_vagrant_boxes = ( platform == 'all' ? config.platforms : config.filter_type(platform) )
selected_boxes = SpecsHelper.find_selected_boxes(default_vagrant_boxes)

SpecsHelper.configure(selected_boxes)

puts "[Acceptance specs] running on #{ServiceTester.configuration.hosts}" if !selected_boxes.empty?
