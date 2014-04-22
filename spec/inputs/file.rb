# encoding: utf-8

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
      File.open(tmp_file, "w") do |fd|
        fd.puts("ignore me 1")
        fd.puts("ignore me 2")
      end

      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      # at this point even if pipeline.ready? == true the plugins
      # threads might still be initializing so we cannot know when the
      # file plugin will have seen the original file, it could see it
      # after the first(s) hello world appends below, hence the
      # retry logic.

      retries = 0
      loop do
        insist { retries } < 20 # 2 secs should be plenty?

        File.open(tmp_file, "a") do |fd|
          fd.puts("hello")
          fd.puts("world")
        end

        if queue.size >= 2
          events = 2.times.collect { queue.pop }
          insist { events[0]["message"] } == "hello"
          insist { events[1]["message"] } == "world"
          break
        end

        sleep(0.1)
        retries += 1
      end
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

    input do |pipeline, queue|
      File.open(tmp_file, "a") do |fd|
        fd.puts("hello")
        fd.puts("world")
      end

      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

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
      File.open(tmp_file, "w") do |fd|
        fd.puts("hello")
        fd.puts("world")
      end

      t = Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      events = 2.times.collect { queue.pop }
      pipeline.shutdown
      t.join

      File.open(tmp_file, "a") do |fd|
        fd.puts("foo")
        fd.puts("bar")
        fd.puts("baz")
      end

      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      events = 3.times.collect { queue.pop }

      insist { events[0]["message"] } == "foo"
      insist { events[1]["message"] } == "bar"
      insist { events[2]["message"] } == "baz"
    end
  end
end
