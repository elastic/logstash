# encoding: utf-8

require "logstash/json"
require "logstash/timestamp"

if ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
  SimpleCov.start do
    add_filter 'spec/'
    add_filter 'vendor/'
  end
end
require "insist"
require "logstash/agent"
require "logstash/pipeline"
require "logstash/event"
require "logstash/logging"
require "insist"
require "stud/try"

$TESTING = true
if RUBY_VERSION < "1.9.2"
  $stderr.puts "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
  $stderr.puts "Options for fixing this: "
  $stderr.puts "  * If doing 'ruby bin/logstash ...' add --1.9 flag to 'ruby'"
  $stderr.puts "  * If doing 'java -jar ... ' add -Djruby.compat.version=RUBY1_9 to java flags"
  raise LoadError
end

$logger = LogStash::Logger.new(STDOUT)
if ENV["TEST_DEBUG"]
  $logger.level = :debug
else
  $logger.level = :error
end

puts("Using Accessor#strict_set for specs")
# mokey path LogStash::Event to use strict_set in tests
# ugly, I know, but this avoids adding conditionals in performance critical section
class LogStash::Event
  def []=(str, value)
    if str == TIMESTAMP && !value.is_a?(LogStash::Timestamp)
      raise TypeError, "The field '@timestamp' must be a LogStash::Timestamp, not a #{value.class} (#{value})"
    end
    @accessors.strict_set(str, value)
  end # def []=
end

RSpec.configure do |config|
  config.filter_run_excluding :redis => true, :socket => true, :performance => true, :elasticsearch => true, :broken => true, :export_cypher => true
end

module LogStash
  module RSpec
    def config(configstr)
      let(:config) { configstr }
    end # def config

    def type(default_type)
      let(:default_type) { default_type }
    end

    def tags(*tags)
      let(:default_tags) { tags }
      puts "Setting default tags: #{@default_tags}"
    end

    def sample(sample_event, &block)
      name = sample_event.is_a?(String) ? sample_event : LogStash::Json.dump(sample_event)
      name = name[0..50] + "..." if name.length > 50

      describe "\"#{name}\"" do
        extend LogStash::RSpec
        let(:pipeline) { LogStash::Pipeline.new(config) }
        let(:event) do
          sample_event = [sample_event] unless sample_event.is_a?(Array)
          next sample_event.collect do |e|
            e = { "message" => e } if e.is_a?(String)
            next LogStash::Event.new(e)
          end
        end

        let(:results) do
          results = []
          count = 0
          pipeline.instance_eval { @filters.each(&:register) }

          event.each do |e|
            extra = []
            pipeline.filter(e) do |new_event|
              extra << new_event
            end
            results << e if !e.cancelled?
            results += extra.reject(&:cancelled?)
          end

          pipeline.instance_eval {@filters.each {|f| f.teardown.tap { |v| results += v if v } if f.respond_to?(:teardown)}}

          # TODO(sissel): pipeline flush needs to be implemented.
          # results += pipeline.flush
          next results
        end

        subject { results.length > 1 ? results: results.first }

        it("when processed", &block)
      end
    end # def sample

    def input(&block)
      it "inputs" do
        pipeline = LogStash::Pipeline.new(config)
        queue = Queue.new
        pipeline.instance_eval do
          @output_func = lambda { |event| queue << event }
        end
        block.call(pipeline, queue)
        pipeline.shutdown
      end
    end # def input

    def agent(&block)
      require "logstash/pipeline"

      it("agent(#{caller[0].gsub(/ .*/, "")}) runs") do
        pipeline = LogStash::Pipeline.new(config)
        pipeline.run
        block.call
      end
    end # def agent

  end # module RSpec
end # module LogStash

class Shiftback
  def initialize(&block)
    @block = block
  end

  def <<(event)
    @block.call(event)
  end
end # class Shiftback
