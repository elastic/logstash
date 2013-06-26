require "test_utils"
require "tempfile"

describe "inputs/file" do
  extend LogStash::RSpec

  describe "starts at the end of an existing file" do
    tmp_file = Tempfile.new('logstash-spec-input-file')

    config <<-CONFIG
      input {
        file {
          type => "blah"
          path => "#{tmp_file.path}"
          sincedb_path => "/dev/null"
        }
      }
    CONFIG

    input do |pipeline, queue|
      File.open(tmp_file, "a") do |fd|
        fd.puts("ignore me")
        fd.puts("ignore me 2")
      end
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      File.open(tmp_file, "a") do |fd|
        fd.puts("hello")
        fd.puts("world")
      end
      events = 2.times.collect { queue.pop } 
      insist { events[0]["message"] } == "hello"
      insist { events[1]["message"] } == "world"
    end
  end

  describe "can start at the beginning of an existing file" do
    tmp_file = Tempfile.new('logstash-spec-input-file')

    config <<-CONFIG
      input {
        file {
          type => "blah"
          path => "#{tmp_file.path}"
          start_position => "beginning"
          sincedb_path => "/dev/null"
        }
      }
    CONFIG

    before(:each) do
      File.open(tmp_file, "w") do |fd|
        fd.puts "hello"
        fd.puts "world"
      end
    end

    after(:each) do
      tmp_file.close!
    end

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      events = 2.times.collect { queue.pop } 
      insist { events[0]["message"] } == "hello"
      insist { events[1]["message"] } == "world"
    end
  end

  describe "restarts at the sincedb value" do
    tmp_file = Tempfile.new('logstash-spec-input-file')
    tmp_sincedb = Tempfile.new('logstash-spec-input-file-sincedb')

    config <<-CONFIG
      input {
        file {
          type => "blah"
          path => "#{tmp_file.path}"
          start_position => "beginning"
          sincedb_path => "#{tmp_sincedb.path}"
        }
      }
    CONFIG

    input do |pipeline, queue|
      File.open(tmp_file, "a") do |fd|
        fd.puts "hello"
        fd.puts "world"
      end
      Thread.new { pipeline.run }
      events = 2.times.collect { queue.pop } 
      pipeline.shutdown

      File.open(tmp_file, "a") do |fd|
        fd.puts "foo"
        fd.puts "bar"
        fd.puts "baz"
      end
      Thread.new { pipeline.run }
      events = 3.times.collect { queue.pop } 
      insist { events[0]["message"] } == "foo"
      insist { events[1]["message"] } == "bar"
      insist { events[2]["message"] } == "baz"
    end
  end
end
