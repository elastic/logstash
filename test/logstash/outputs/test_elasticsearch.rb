require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"

class TestOutputElasticSearch < LogStash::TestCase
  def em_setup_try
    version = "0.14.4"

    # Block for initial setup
    system("make -C ../../setup/elasticsearch/ init-elasticsearch-#{version} wipe-elasticsearch-#{version}")
    EventMachine::popen("make -C ../../setup/elasticsearch/ run-elasticsearch-#{version}")
    #do |output, status|
      #puts output.split("\n").map { |a| "elasticsearch> #{a}" }.join("\n")
      #puts "ElasticSearch exited with code '#{status}'"
    #end

    tries = 10
    es_setup = proc do
      tries -= 1
      begin
        # TODO(sissel): This will never actually fire an exception if ES isn't up.
        # because output/elasticsearch does things async, the exception
        # is tossed up much later.
        #
        # We'll need a way to attach exception handlers to input/output/filter/agent
        # in order to make them better testable?
        # Also, an agent "ready" callback would make this kind of setup easier
        # to manage and could also be used in non-testing for sending a "Go" signal
        # if we wanted such a thing.
        #
        em_setup
        puts "ElasticSearch is ready"
        return
      rescue => e
        # Abort if we are out of tries.
        if tries <= 0
          puts "NO MORE TRIES LEFT. ABORTING"
          raise e 
        end

        # Try again in a few seconds otherwise
        puts "Waiting for elasticsearch to be ready... (#{e.inspect})"
        EventMachine.add_timer(3) do
          es_setup.call
        end
      end

    end # proc es_setup

    EventMachine.next_tick do
      es_setup.call
    end
  end # def em_setup_try

  def em_setup
    config = {
      "inputs" => {
        @type => [
          "internal:///"
        ]
      },
      "outputs" => [
        "elasticsearch://localhost:9200/logstashtesting/logs"
      ]
    }

    super(config)
  end # def em_setup

  def test_elasticsearch_basic
    EventMachine::run do
      em_setup_try

      EventMachine.add_timer(20) do
        EventMachine.stop_event_loop
      end
    end
  end

  def teardown
    if @stomp_pid
      Process.kill("KILL", @stomp_pid)
    end
  end # def teardown
end # class TestOutputElasticSearch
