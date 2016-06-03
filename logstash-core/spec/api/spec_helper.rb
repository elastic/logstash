# encoding: utf-8
API_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "logstash", "api"))

require "logstash/devutils/rspec/spec_helper"
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require "lib/api/support/resource_dsl_methods"
require 'rspec/expectations'
require "logstash/settings"
require 'rack/test'
require 'rspec'
require "json"

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
    @config_str   = "input { generator {count => 0} } output { }"
    args = {
      "config.reload.automatic" => false,
      "metric.collect" => true,
      "log.level" => "debug",
      "node.name" => "test_agent",
      "http.port" => rand(9600..9700),
      "http.environment" => "test",      
      "config.string" => @config_str,
      "pipeline.batch.size" => 1,
      "pipeline.workers" => 1
    }
    @settings = ::LogStash::SETTINGS.clone.merge(args)

    @agent = LogStash::DummyAgent.new(@settings)
  end

  def start
    agent.register_pipeline("main", @settings)
    @runner = Thread.new(agent) do |_agent|
      _agent.execute
    end

    wait_until_ready
  end

  def stop
    agent.shutdown
    Thread.kill(@runner)
    sleep 0.1 while !@runner.stop?
  end

  private

  def wait_until_ready
    # # Wait until the service and pipeline have started
    # while !(LogStash::Api::Service.instance.started? && agent.pipelines["main"].running?) do
    #   sleep 0.5
    # end
  end
end

##
# Method used to wrap up a request in between of a running
# pipeline, this makes the whole execution model easier and
# more contained as some threads might go wild.
##
def do_request(&block)
  runner = LogStashRunner.new
  runner.start
  ret_val = block.call
  runner.stop
  ret_val
end

RSpec::Matchers.define :be_available? do
  match do |plugin|
    begin
      Gem::Specification.find_by_name(plugin["name"])
      true
    rescue
      false
    end
  end
end

shared_context "api setup" do
  before :all do
    @runner = LogStashRunner.new
    @runner.start
  end

  after :all do
    @runner.stop
  end

  include Rack::Test::Methods

  def app()
    described_class.new(nil, @runner.agent)
  end
end
