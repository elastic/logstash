# encoding: utf-8
require "test_utils"
require "tempfile"

describe "inputs/pipe" do
  extend LogStash::RSpec

  #Minimal value to avoid an endless loop when enabling debug log
  @@wait_on_restart = 0.3

  describe "echo - once" do
    event_count = 1
    tmp_file = Tempfile.new('logstash-spec-input-pipe')

    config <<-CONFIG
    input {
      pipe {
        command => "echo ☹"
        restart => "never"
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

  describe "echo - forever" do
    event_count = 10
    tmp_file = Tempfile.new('logstash-spec-input-pipe')

    config <<-CONFIG
    input {
      pipe {
        command => "echo ☹"
        restart => "always"
        wait_on_restart => 0
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
        restart => "never"
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

  #This test is reading the log expecting only warn level,
  #so enabling debug logging will make it fail
  describe "invalid command - do not restart" do
    error_count = 1
    config <<-CONFIG
    input {
      pipe {
        command => "@@@Invalid_Command_Test@@@"
        restart => "never"
      }
    }
    CONFIG
    logger = Cabin::Channel.get(LogStash)
    log_messages = Queue.new
    logger.subscribe(log_messages)
    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?
      #No event pushed to the queue
      insist { queue.empty?} == true
      errors = error_count.times.collect { log_messages.pop }
      error_count.times do |i|
        insist { errors[i][:message] } == "Exception while running command"
      end
      #The input should not restart, there is no more error logs
      retries = 0
      has_more = false
      while !has_more && retries < 5 do
        begin
          log_messages.pop(true)
          has_more = true
        rescue => e
        end
        sleep(0.1)
        retries += 1
      end
      if has_more 
        raise "Input should not restart"
      end
    end # input
  end

  #This test is reading the log expecting only warn level,
  #so enabling debug logging will make it fail
  describe "restart on error" do
    error_count = 3
    config <<-CONFIG
    input {
      pipe {
        command => "@@@Invalid_Command_Test@@@"
        restart => "error"
        wait_on_restart => #{@@wait_on_restart}
      }
    }
    CONFIG

    logger = Cabin::Channel.get(LogStash)
    log_messages = Queue.new
    logger.subscribe(log_messages)
    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?
      #No event pushed to the queue
      insist { queue.empty?} == true
      errors = error_count.times.collect { log_messages.pop }
      error_count.times do |i|
        insist { errors[i][:message] } == "Exception while running command"
      end
    end # input
  end

end
