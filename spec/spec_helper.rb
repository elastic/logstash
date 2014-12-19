require "logstash/devutils/rspec/spec_helper"
require "logstash/agent"
require "logstash/pipeline"
require "logstash/event"


RSpec.configure do |config|
  config.formatter = 'documentation'
  config.color    = true
end if ENV['LOGSTASH_TEST']

module ConditionalFanciness
  def description
    return example.metadata[:example_group][:description_args][0]
  end

  def conditional(expression, &block)
    describe(expression) do
      config <<-CONFIG
        filter {
          if #{expression} {
            mutate { add_tag => "success" }
          } else {
            mutate { add_tag => "failure" }
          }
        }
      CONFIG
      instance_eval(&block)
    end
  end
end

class NullRunner
  def run(args); end
end


class DummyInput < LogStash::Inputs::Base
  config_name "dummyinput"
  milestone 2

  def register
  end

  def run(queue)
  end

  def teardown
  end
end

class DummyCodec < LogStash::Codecs::Base
  config_name "dummycodec"
  milestone 2

  def decode(data) 
    data
  end

  def encode(event) 
    event
  end

  def teardown
  end
end

class DummyOutput < LogStash::Outputs::Base
  config_name "dummyoutput"
  milestone 2

  attr_reader :num_teardowns

  def initialize(params={})
    super
    @num_teardowns = 0
  end

  def register
  end

  def receive(event)
  end

  def teardown
    @num_teardowns += 1
  end
end

class TestPipeline < LogStash::Pipeline
  attr_reader :outputs
end


def load_fixtures(name, *pattern)
  content = File.read(File.join('spec', 'fixtures', name))
  content = content % pattern if !pattern.empty?
  content
end

def sample_logstash_event
  LogStash::Event.new(
    "@timestamp" => Time.iso8601("2013-01-01T00:00:00.000Z"),
    "type" => "sprintf",
    "message" => "hello world",
    "tags" => [ "tag1" ],
    "source" => "/home/foo",
    "a" => "b",
    "c" => {
      "d" => "f",
      "e" => {"f" => "g"}
    },
    "f" => { "g" => { "h" => "i" } },
    "j" => {
      "k1" => "v",
      "k2" => [ "w", "x" ],
      "k3" => {"4" => "m"},
      5 => 6,
      "5" => 7
    },
    "@metadata" => { "fancy" => "pants", "have-to-go" => { "deeper" => "inception" } }
  )
end

def sample_from(events, config)
  pipeline = LogStash::Pipeline.new(config)
  sample_with(events, pipeline)
end

def sample(events)
  sample_with(events, pipeline)
end

def sample_with(events, pipeline)
  events = [events] unless events.is_a?(Array)
  events.map! do |e|
    e = { "message" => e } if e.is_a?(String)
    LogStash::Event.new(e)
  end
  results = []
  pipeline.instance_eval { @filters.each(&:register) }

  events.each do |e|
    pipeline.filter(e) {|new_event| results << new_event }
  end
  pipeline.flush_filters(:final => true) do |e|
    results << e unless e.cancelled?
  end
  results.to_a.map! { |m| m.to_hash }
  (results.count == 1 ? results.first : results)
end
