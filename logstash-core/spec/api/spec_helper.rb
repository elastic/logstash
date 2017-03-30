# encoding: utf-8
API_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "logstash", "api"))

require "stud/task"
require "logstash/devutils/rspec/spec_helper"
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require "lib/api/support/resource_dsl_methods"
require_relative "../support/mocks_classes"
require_relative "../support/helpers"
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
    def start_webserver
      http_address = "#{Socket.gethostname}:#{::LogStash::WebServer::DEFAULT_PORTS.first}"
      @webserver = Struct.new(:address).new(http_address)
      self.metric.gauge([], :http_address, http_address)
    end

    def stop_webserver; end
  end
end

##
# Class used to wrap and manage the execution of an agent for test,
# this helps a lot in order to have a more integrated test for the
# web api, could be also used for other use cases if generalized enough
##
class LogStashRunner

  attr_reader :config_str, :agent, :pipeline_settings

  def initialize

    require "securerandom"
    id = SecureRandom.uuid

    @config_str   = "input { generator {id => 'api-generator-pipeline-#{id}' count => 100 } } output { dummyoutput {} }"

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
    source_loader = LogStash::Config::SourceLoader.new
    source_loader.configure_sources(LogStash::Config::Source::Local.new(@settings))
    @agent = LogStash::DummyAgent.new(@settings, source_loader)
  end

  def start
    # We start a pipeline that will generate a finite number of events
    # before starting the expectations
    @agent_task = Stud::Task.new { agent.execute }
    @agent_task.wait
  end

  def stop
    agent.shutdown
  end
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
    clear_data_dir
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
