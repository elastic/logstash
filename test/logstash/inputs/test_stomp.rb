require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "logstash/testcase"
require "logstash/agent"
require "logstash/stomp/handler"
require "logstash/logging"

# TODO(sissel): Add tests coverage for authenticated stomp sessions
# TODO(sissel): What about queue vs fanout vs topic?

class TestInputStomp < LogStash::TestCase
  def em_setup
    @flags ||= []

    # Run stompserver in debug mode if desired.
    @flags << "-d" if $DEBUG

    # Launch stomp server on a random port
    stomp_done = false
    @stomp_pid = nil
    1.upto(30) do
      @port = (rand * 30000 + 20000).to_i
      @stomp_pid = Process.fork do
        args = ["-p", @port.to_s, *@flags]
        stompbin = Gem.bin_path('stompserver', 'stompserver')
        exec("/proc/$$/exe", "ruby", "-rubygems", stompbin, *args)
        #$0 = "stompserver"
        #ARGV.clear
        #ARGV.unshift *args
        #gem 'stompserver'
        $stderr.puts($!)
        exit 1
      end
      
      # Let stompserver start up and try to start listening.
      # Hard to otherwise test this. Maybe a tcp connection with timeouts?
      sleep(2)
      Process.waitpid(@stomp_pid, Process::WNOHANG)
      if $? != nil and $?.exited?
        # Try again
      else
        stomp_done = true
        break
      end
    end

    if !stomp_done
      raise "Stompserver failed to start (failure to find ephemeral port? stompserver not installed?)"
    end

    @queue = "/queue/testing"
    config = {
      "inputs" => {
        @type => [
          "stomp://localhost:#{@port}#{@queue}"
        ]
      },
      "outputs" => [
        "internal:///"
      ]
    }

    super(config)

    @stomp = EventMachine::connect("127.0.0.1", @port, LogStash::Stomp::Handler,
                                   nil, LogStash::Logger.new(STDERR),
                                   URI.parse(config["inputs"][@type][0]))
    @stomp.should_subscribe = false
  end # def em_setup

  def test_stomp_basic
    inputs = [
      LogStash::Event.new("@message" => "hello world", "@type" => @type),
      LogStash::Event.new("@message" => "one two three", "@type" => @type),
      LogStash::Event.new("@message" => "one two three", "@type" => @type,
                          "@fields" => { "field1" => "value1"})
    ]
    EventMachine::run do
      em_setup
      expected_events = inputs.clone
      @output.subscribe do |event|
        expect = expected_events.shift
        #ap :event => event.to_hash

        assert_equal(expect.message, event.message, "@message")
        assert_equal(expect.type, event.type, "@type")
        assert_equal(expect.tags, event.tags, "@tags")
        assert_equal(expect.timestamp, event.timestamp, "@tags")
        assert_equal(expect.fields, event.fields, "@tags")
        @agent.stop if expected_events.size == 0
      end

      timer = EM::PeriodicTimer.new(0.2) do
        next if !@stomp.ready

        if inputs.size == 0
          timer.cancel
          next
        end

        event = inputs.shift
        @stomp.send @queue, event.to_json
      end
    end
  end # def test_stomp_basic

  def teardown
    if @stomp_pid
      Process.kill("KILL", @stomp_pid)
    end
  end # def teardown
end # class TestInputStomp
