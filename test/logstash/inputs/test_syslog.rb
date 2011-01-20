require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "logstash/testcase"
require "logstash/agent"

class TestInputSyslog < LogStash::TestCase
  def em_setup
    config = {
      "inputs" => {
        @type => [
        ]
      },
      "outputs" => [
        "internal:///"
      ]
    }

    done = false
    # TODO(sissel): refactor this into something reusable?
    1.upto(30) do
      begin
        # Grab a a random port to listen on.
        @port = (rand * 30000 + 20000).to_i
        config["inputs"][@type] = ["syslog://127.0.0.1:#{@port}"]
        super(config)
        done = true
        break
      rescue => e
        # Verified working with EventMachine 0.12.10
        if e.is_a?(RuntimeError) && e.message == "no acceptor"
          # ignore, it's likely we tried to listen on a port already in use.
        else
          raise e
        end
      end # rescue
    end # loop for an ephemeral port

    if !done
      raise "Couldn't find a port to bind on."
    end

    # Override input.
    @connection = EventMachine::connect("127.0.0.1", @port)
    @input = EventMachine::Channel.new
    @input.subscribe do |message|
      @connection.send_data(message)
    end
  end # def em_setup

  def test_syslog_normal
    inputs = [
      "<1>Dec 19 12:30:48 snack nagios3: Auto-save of retention data completed successfully.",
      "<2>Dec 19 11:35:32 carrera sshd[28882]: Failed password for invalid user PlcmSpIp from 121.9.210.245 port 48846 ssh2"
    ]

    EventMachine.run do
      em_setup

      expected_messages = inputs.clone
      @output.subscribe do |event|
        expect = expected_messages.shift
        #assert_equal(expect, event.message)
        assert_equal(expect.split(" ", 5)[-1], event.message)
        if expected_messages.size == 0
          @agent.stop
        end
      end

      EM::PeriodicTimer.new(0.3) do 
        @input.push inputs.shift + "\n" if inputs.size > 0
      end
    end
  end
end # class TestInputSyslog
