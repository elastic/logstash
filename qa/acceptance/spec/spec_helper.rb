# encoding: utf-8
require 'runner-tool'
require_relative '../../rspec/helpers'
require_relative '../../rspec/matchers'
require_relative 'config_helper'

ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..'))
$LOAD_PATH.unshift File.join(ROOT, 'logstash-core/lib')

RunnerTool.configure

RSpec.configure do |c|
  c.include ServiceTester
end
