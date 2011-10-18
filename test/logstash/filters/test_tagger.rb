require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash/loadlibs"
require "logstash"
require "logstash/filters"
require "logstash/filters/tagger"
require "logstash/event"
require "json"
require "ruby-debug"

describe LogStash::Filters::Tagger do
  before do
    @typename = "metlog"
  end

  def config(cfg)
        # this method is *not* executed automatically
        # 
        # A bit confused here. When you set the type, the configuration
        # takes in a string, but the testcase expects a list?

        cfg["type"] = ["metlog"]
        cfg['pattern'] = ['logger', "toy2"]
        cfg['add_tag'] = ['metlog_dest_bagheera']

        @filter = LogStash::Filters::Tagger.new(cfg)
        @filter.register
  end # def config

  test "logger based routing" do
      # weird - config {} doesn't seem to work
      config ({})

      event = LogStash::Event.new
      event.type = @typename
      
      # TODO: refactor out the creation of the JSON blob
      jdata = { 'timestamp' => '2011-10-13T09:43:44.386392',
          'metadata' => {'some_data' => 'foo' },
          'type' => 'error',
          'logger' => 'toy2',
          'severity' => 0,
          'message' => 'some log text',
      }

      jdata.each { |k, v| event[k] = v }

      @filter.filter(event)

      # Check that we've got just the tags that we're expecting
      assert event.tags.include? "metlog_dest_bagheera"
      assert !(event.tags.include?"metlog_dest_sentry")

  end # testing a single match

end # TestFilterGrep
