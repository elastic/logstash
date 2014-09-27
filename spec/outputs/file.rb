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

  describe "ship lots of events to a file with rotation" do
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
          max_size => 300
          max_files => 0
        }
      }
    CONFIG

    agent do
      # we should have a less or equal number of rotation logs
      file_name_filter = tmp_file.path + ".*"
      files = Dir[file_name_filter]
      insist {files.count} > 0
      
      # be a good citicen and delete the roation files again
      files.each { |file_entry|
        File.delete(file_entry)
      }
    end # agent
  end
  
  describe "ship lots of events to a file with rotation and retirement" do
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
              max_size => 300
              max_files => 3
          }
      }
      CONFIG
      
      agent do
          # we should have a less or equal number of rotation logs now
          file_name_filter = tmp_file.path + ".*"
          files = Dir[file_name_filter]
          insist {files.count} <= 3
          
          # be a good citicen and delete the rotation files again
          files.each { |file_entry|
              File.delete(file_entry)
          }
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
