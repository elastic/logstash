require "test_utils"

class LogStash::Inputs::Testbaseinput < LogStash::Inputs::Base
  config_name "testbaseinput"
  milestone 1
  default :codec, "plain"

  config :message, :validate => :string

  def register
  end

  def run(queue)
    codec.decode(message) do |event|
      queue << event
    end
  end
end

describe "inputs/base" do
  extend LogStash::RSpec

  before do
    LogStash::Plugin.stub(:require).and_call_original
    LogStash::Plugin.stub(:require).with('logstash/inputs/testbaseinput').and_return(true)
    Time.stub(:now).and_return(Time.at(1))
  end

  describe "generate events" do
    config <<-CONFIG
      input {
        testbaseinput {
          type => "blah"
          message => "hello base test"
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }

      event = queue.pop

      insist { event["@version"] } == "1"
      insist { event["@timestamp"] } == Time.at(1).utc
      insist { event["type"] } == "blah"
      insist { event["message"] } == "hello base test"

      pipeline.shutdown
    end # input
  end
end
