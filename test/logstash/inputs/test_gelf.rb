require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash/testcase"
require "logstash/agent"
require "logstash/logging"
require "logstash/inputs/gelf"
require "gelf" # rubygem 'gelf'

describe LogStash::Inputs::Gelf do
  before do
    @input = LogStash::Inputs::Gelf.new("type" => ["foo"])
    @input.register
  end # before

  after do
    @input.teardown
    # This plugin has no proper teardown yet.
  end # after

  test "gelf basic input" do
    # gelf notifier defaults here are OK, match the defaults of the gelf input
    queue = Queue.new
    thread = Thread.new { @input.run(queue) }

    # Let the input start listening. This is a crappy solution, but until
    # plugins can notify "I am ready!" testing will be a bit awkward.
    sleep(2)

    gelf = GELF::Notifier.new 
    gelf.notify!("Hello world")
    gelf.notify!(:full_message => "Hello world", :short_message => "Hello world", :foo => "bar")
    count = 2

    events = []
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
    assert_equal("Hello world", events.first.message)
    assert_equal("Hello world", events.last.message)
    assert_equal("bar", events.last.fields["foo"])
  end # test gelf input defaults
end # testing for LogStash::Outputs::ElasticSearch
