require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/inputs/file"

require "tempfile"

require "mocha"

describe LogStash::Inputs::File do

  test "file input sets source properly for events" do
    stubbed_hostname = "mystubbedhostname"
    Socket.stubs(:gethostname).returns(stubbed_hostname)

    logfile = Tempfile.new("logstash")
    begin
      @input = LogStash::Inputs::File.new("type" => ["testing"], "path" => [logfile.path])
      @input.register

      queue = Queue.new

      Thread.new { @input.run(queue) }
      
      event = nil
      start = Time.now
      while event.nil? and (Time.now - start) <= 5.0
        logfile.write("This is my log message.\n")
        logfile.flush

        begin
          event = queue.pop(true)
        rescue ThreadError => error
          raise error unless error.to_s == "queue empty"
          sleep(0.05)
        end
      end

      @input.teardown

      refute_nil event

      uri = Addressable::URI.parse(event.source)
      assert_equal "file", uri.scheme
      assert_equal stubbed_hostname, uri.host
      assert_equal logfile.path, uri.path
    ensure
      logfile.close
      logfile.unlink
    end
  end

  test "file input sets source_path properly for events" do
    logfile = Tempfile.new("logstash")
    begin
      @input = LogStash::Inputs::File.new("type" => ["testing"], "path" => [logfile.path])
      @input.register

      queue = Queue.new

      Thread.new { @input.run(queue) }
      
      event = nil
      start = Time.now
      while event.nil? and (Time.now - start) <= 5.0
        logfile.write("This is my log message.\n")
        logfile.flush

        begin
          event = queue.pop(true)
        rescue ThreadError => error
          raise error unless error.to_s == "queue empty"
          sleep(0.05)
        end
      end

      @input.teardown

      assert_equal(logfile.path, event["@source_path"])
    ensure
      logfile.close
      logfile.unlink
    end
  end
  
  test "file input should raise an ArgumentError when a relative path is specified" do
    assert_raises(ArgumentError) {
      LogStash::Inputs::File.new("type" => ["testing"], "path" => ["./relative/path"])
    }
    
    assert_raises(ArgumentError) {
      LogStash::Inputs::File.new("type" => ["testing"], "path" => ["../relative/path"])
    }
    
    assert_raises(ArgumentError) {
      LogStash::Inputs::File.new("type" => ["testing"], "path" => ["relative/path"])
    }
    
    assert_raises(ArgumentError) {
      LogStash::Inputs::File.new("type" => ["testing"], "path" => ["~/relative/path"])
    }
  end
  
  test "file input should raise an ArgumentError with a useful message when a relative path is specified" do
    relative_path = "./relative/path"
    the_exception = nil
    begin
      LogStash::Inputs::File.new("type" => ["testing"], "path" => [relative_path])
    rescue ArgumentError => e
      the_exception = e
    end
    
    refute_nil(the_exception)
    assert_equal("File paths must be absolute, relative path specified: #{relative_path}", e.message)
  end

  test "file input should not raise an exception for an absolute path containing wildcards" do
    begin
      LogStash::Inputs::File.new("type" => ["testing"], "path" => ["/absolute/path/*"])
    rescue ArgumentError => e
      flunk "An absolute path containing a wildcard should be valid"
    end
  end

end # testing for LogStash::Inputs::File
