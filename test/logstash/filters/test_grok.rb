require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash"
require "logstash/loadlibs"
require "logstash/filters/grok"
require "logstash/event"

describe LogStash::Filters::Grok do
  before do
    @typename = "groktest"
    @filter = nil
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = [cfg[key]]
      end
    end
    @filter = LogStash::Filters::Grok.new(cfg)
    @filter.register
  end

  test "performance" do
    config "pattern" => [ "%{SYSLOGLINE}" ]
    puts "Doing performance test"

    iterations = 50000

    logsource = "evita"
    timestamp = "Mar 16 00:01:25"
    message = "connect from camomile.cloud9.net[168.100.1.3]"
    program = "postfix/smtpd"
    pid = "1713"

    message = "#{timestamp} #{logsource} #{program}[#{pid}]: #{message}"
    start = Time.now
    1.upto(iterations).each do |i|
      event = LogStash::Event.new("@message" => message, "@type" => @typename)
      @filter.filter(event)
    end

    duration = Time.now - start
    max_duration = 20
    puts "filters/grok speed test; #{iterations} iterations: #{duration} " \
         "seconds (#{"%.3f" % (iterations / duration)} per sec)"
    assert(duration < max_duration,
           "Should be able to do #{iterations} grok parses in less " \
           "than #{max_duration} seconds, got #{duration} seconds")
  end # performance test

end # tests for LogStash::Filters::Grok
