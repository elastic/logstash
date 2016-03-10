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

module LogStash
  class DummyAgent < Agent
    def fetch_config(settings)
      "input { generator {count => 0} } output { }"
    end

    def start_webserver; end
    def stop_webserver; end
  end
end

##
# Class used to wrap and manage the execution of an agent for test,
# this helps a lot in order to have a more integrated test for the
# web api, could be also used for other use cases if generalized enought
##
class LogStashRunner

  attr_reader :config_str, :agent, :pipeline_settings

  def initialize
    args = [
      :logger => Cabin::Channel.get(LogStash),
      :auto_reload => false,
      :collect_metric => true,
      :debug => false,
      :node_name => "test_agent",
      :web_api_http_port => rand(9600..9700)
    ]

    @config_str   = "input { generator {count => 0} } output { }"
    @agent = LogStash::DummyAgent.new(*args)
    @pipeline_settings ||= { :pipeline_id => "main",
                             :config_str => config_str,
                            :pipeline_batch_size => 1,
                            :flush_interval => 1,
                            :pipeline_workers => 1 }
  end

  def start
    agent.register_pipeline("main", pipeline_settings)
    @runner = Thread.new(agent) do |_agent|
      _agent.execute
    end
    wait_until_snapshot_received
  end

  def stop
    agent.shutdown
    Thread.kill(@runner)
    sleep 0.1 while !@runner.stop?
  end

  private

  def wait_until_snapshot_received
    while !LogStash::Api::Service.instance.started? do
      sleep 0.5
    end
  end
end


##
# Method used to wrap up a request in between of a running
# pipeline, this makes the hole execution model easier and
# more contained as some threads might go wild.
##
def do_request(&block)
  runner = LogStashRunner.new
  runner.start
  ret_val = block.call
  runner.stop
  ret_val
end

##
# Helper module that setups necessary mocks when doing the requests,
# this could be just included in the test and the runner will be
# started managed for all tests.
##
module LogStash; module RSpec; module RunnerConfig
  def self.included(klass)
    klass.before(:all) do
      LogStashRunner.instance.start
    end

    klass.before(:each) do
      runner = LogStashRunner.instance
      allow(LogStash::Instrument::Collector.instance).to receive(:agent).and_return(runner.agent)
    end

    klass.after(:all) do
      LogStashRunner.instance.stop
    end
  end
end; end; end
