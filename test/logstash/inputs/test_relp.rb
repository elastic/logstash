require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/inputs/relp"
require "logstash/util/relp"

require "mocha"

#TODO: I just copy/pasted all those^ which ones do I actually need?

describe LogStash::Inputs::Relp do

  before do
    #TODO: port 15515 is what I tend to use; pick a default?
    @input = LogStash::Inputs::Relp.new("type" => ["relp"],
        "host" => ["127.0.0.1"], "port" => [15515])
    @input.register
  end # before

  after do
    @input.teardown
  end # after

  test "Basic handshaking/message transmission" do
    queue = Queue.new
    thread = Thread.new { @input.run(queue) }

    # Let the input start listening. This is a crappy solution, but until
    # plugins can notify "I am ready!" testing will be a bit awkward.
    # TODO: could we not pull this from the logger?
    sleep(2)

    begin
      rc=RelpClient.new('127.0.0.1',15515,['syslog'])
      rc.syslog_write('This is the first relp test message')
      rc.syslog_write('This is the second relp test message')
      rc.syslog_write('This is the third relp test message')
      rc.syslog_write('This is the fourth relp test message')
      rc.syslog_write('This is the fifth relp test message')
      count=5

      rc.close

      events=[]

      start = Time.new
  
      # Allow maximum of 2 seconds for events to show up
      while (Time.new - start) < 2 && events.size != count
        begin
          event = queue.pop(true) # don't block
          events << event if event
        rescue ThreadError => e
          # Fail on anything other than "queue empty"
          raise e if e.to_s != "queue empty"
          sleep(0.05)
        end
      end

      assert_equal(count, events.size, "Wanted #{count}, but got #{events.size} events")
      assert_equal("This is the first relp test message", events.first.message)
      assert_equal("This is the fifth relp test message", events.last.message)

    rescue Relp::RelpError => re
      flunk re.class.to_s + ': ' + re.to_s#TODO: is there not a proper way to do this?
    end
  end

  test "RelpServer rejects invalid commands" do
    #Need it to close the connection, but not bring down the whole server
    queue = Queue.new
    thread = Thread.new { @input.run(queue) }

    logger=Queue.new
    (@input.instance_eval { @logger }).subscribe(logger)

    assert_raises(Relp::ConnectionClosed) do
      rc = RelpClient.new('127.0.0.1',15515,['syslog'])
      badframe = Hash.new
      badframe['command'] = 'badcommand'
      rc.frame_write(badframe)
      #We can't detect that it's closed until we try to write to it again
      #(delay is required for connection to be closed)
      sleep 1
      rc.frame_write(badframe)
    end
    assert_equal("Relp error: Relp::InvalidCommand badcommand",logger.pop[:message])
  end

  test "RelpServer rejects inappropriate commands" do
    #Need it to close the connection, but not bring down the whole server
    queue = Queue.new
    thread = Thread.new { @input.run(queue) }

    logger = Queue.new
    (@input.instance_eval { @logger }).subscribe(logger)

    assert_raises(Relp::ConnectionClosed) do
      rc = RelpClient.new('127.0.0.1',15515,['syslog'])
      badframe = Hash.new
      badframe['command'] = 'open'#it's not expecting open again
      rc.frame_write(badframe)
      #We can't detect that it's closed until we try to write to it again
      #(but with something other than an open)
      sleep 1
      badframe['command'] = 'syslog'
      rc.frame_write(badframe)
    end
    assert_equal("Relp error: Relp::InappropriateCommand open expecting syslog",
                 logger.pop[:message])

  end

  test "RelpServer refuses to connect if no syslog command available" do

    logger = Queue.new
    (@input.instance_eval { @logger }).subscribe(logger)

    assert_raises(Relp::RelpError) do
      queue = Queue.new
      thread = Thread.new { @input.run(queue) }
      rc = RelpClient.new('127.0.0.1',15515)
    end
 
    assert_equal("Relp client incapable of syslog",logger.pop[:message])
  end

end # testing for LogStash::Inputs::File

#TODO: structured error logging
