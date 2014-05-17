# encoding: utf-8
require "test_utils"
require "tempfile"

describe "inputs/pipe" do
  extend LogStash::RSpec

  describe "echo" do
    event_count = 1
    tmp_file = Tempfile.new('logstash-spec-input-pipe')

    config <<-CONFIG
    input {
      pipe {
        command => "echo ☹"
      }
    }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      events = event_count.times.collect { queue.pop }
      event_count.times do |i|
        insist { events[i]["message"] } == "☹"
      end
    end # input
  end

  describe "tail -f" do
    event_count = 10
    tmp_file = Tempfile.new('logstash-spec-input-pipe')

    config <<-CONFIG
    input {
      pipe {
        command => "tail -f #{tmp_file.path}"
      }
    }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      File.open(tmp_file, "a") do |fd|
        event_count.times do |i|
          # unicode smiley for testing unicode support!
          fd.puts("#{i} ☹")
        end
      end
      events = event_count.times.collect { queue.pop }
      event_count.times do |i|
        insist { events[i]["message"] } == "#{i} ☹"
      end
    end # input
  end

end
