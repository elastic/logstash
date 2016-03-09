# encoding: utf-8
API_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "logstash", "api"))

require "logstash/devutils/rspec/spec_helper"

require 'rack/test'
require 'rspec'
require "json"

ENV['RACK_ENV'] = 'test'

Rack::Builder.parse_file(File.join(API_ROOT, 'init.ru'))

def read_fixture(name)
  path = File.join(File.dirname(__FILE__), "fixtures", name)
  File.read(path)
end

args = [
  :logger => Cabin::Channel.get(LogStash),
  :auto_reload => false,
  :collect_metric => true,
  :debug => false,
  :node_name => "test_agent",
  :web_api_http_port => rand(9600..9700)
]

agent = LogStash::Agent.new(*args)
config_str   = "input { generator {count => 0} } output { null { } }"
pipeline_settings ||= { :pipeline_id => "main",
                        :config_str => config_str,
                        :pipeline_batch_size => 1,
                        :flush_interval => 1,
                        :pipeline_workers => 1 }
agent.register_pipeline("main", pipeline_settings)

Thread.new(agent) do |_agent|
  _agent.execute
end

RSpec.configure do |config|
  config.before(:each) do
    allow(agent).to receive(:start_webserver)
    allow(agent).to receive(:stop_webserver)
    allow(LogStash::Instrument::Collector.instance).to receive(:agent).and_return(agent)
  end
end

def wait_until_snapshot_received
  while !LogStash::Api::Service.instance.started? do
    sleep 0.5
  end
end
wait_until_snapshot_received
