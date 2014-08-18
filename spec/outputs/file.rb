require "test_utils"
require "logstash/outputs/file"
require "logstash/json"
require "tempfile"

describe LogStash::Outputs::File do
  extend LogStash::RSpec

  describe "ship lots of events to a file" do
    event_count = 10000 + rand(500)
    tmp_file = Tempfile.new('logstash-spec-output-file')

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        file {
          path => "#{tmp_file.path}"
        }
      }
    CONFIG

    agent do
      line_num = 0
      # Now check all events for order and correctness.
      File.foreach(tmp_file) do |line|
        event = LogStash::Event.new(LogStash::Json.load(line))
        insist {event["message"]} == "hello world"
        insist {event["sequence"]} == line_num
        line_num += 1
      end
      insist {line_num} == event_count
    end # agent
  end

  describe "ship lots of events to a file gzipped" do
    event_count = 10000 + rand(500)
    tmp_file = Tempfile.new('logstash-spec-output-file')

    config <<-CONFIG
      input {
        generator {
          message => "hello world"
          count => #{event_count}
          type => "generator"
        }
      }
      output {
        file {
          path => "#{tmp_file.path}"
          gzip => true
        }
      }
    CONFIG

    agent do
      line_num = 0
      # Now check all events for order and correctness.
      Zlib::GzipReader.open(tmp_file.path).each_line do |line|
        event = LogStash::Event.new(LogStash::Json.load(line))
        insist {event["message"]} == "hello world"
        insist {event["sequence"]} == line_num
        line_num += 1
      end
      insist {line_num} == event_count
    end # agent
  end
end
