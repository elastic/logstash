require "rubygems"
$:.unshift File.dirname(__FILE__) + "/../../../lib"
$:.unshift File.dirname(__FILE__) + "/../../"

require "test/unit"
require "logstash"
require "logstash/loadlibs"
require "logstash/filters"
require "logstash/filters/grok"
require "logstash/event"

class TestFilterGrok < Test::Unit::TestCase

  def test_name(name)
    @typename = name.gsub(/[ ]/, "_")
  end

  def config(cfg)
    cfg["type"] = @typename
    cfg.each_key do |key|
      if cfg[key].is_a?(String)
        cfg[key] = cfg[key].to_a
      end
    end

    @filter = LogStash::Filters::Grok.new(cfg)
    @filter.register
  end

  def test_grok_normal
    test_name "groknormal"
    config "pattern" => [ "%{SYSLOGLINE}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    logsource = "evita"
    timestamp = "Mar 16 00:01:25"
    message = "connect from camomile.cloud9.net[168.100.1.3]"
    program = "postfix/smtpd"
    pid = "1713"

    #event.message = "Mar 16 00:01:25 evita postfix/smtpd[1713]: connect from camomile.cloud9.net[168.100.1.3]"
    event.message = "#{timestamp} #{logsource} #{program}[#{pid}]: #{message}"

    @filter.filter(event)
    assert_equal(event.fields["logsource"], [logsource], 
                 "Expected field 'logsource' to be [#{logsource.inspect}], is #{event.fields["logsource"].inspect}")

    assert_equal(event.fields["timestamp"], [timestamp], "Expected field 'timestamp' to be [#{timestamp.inspect}], is #{event.fields["timestamp"].inspect}")

    assert_equal(event.fields["message"], [message], "Expected field 'message' to be ['#{message.inspect}'], is #{event.fields["message"].inspect}")

    assert_equal(event.fields["program"], [program], "Expected field 'program' to be ['#{program.inspect}'], is #{event.fields["program"].inspect}")

    assert_equal(event.fields["pid"], [pid], "Expected field 'pid' to be ['#{pid.inspect}'], is #{event.fields["pid"].inspect}")
  end # def test_grok_normal

  def test_speed
    test_name "groknormal"
    config "pattern" => [ "%{SYSLOGLINE}" ]

    iterations = 5000

    start = Time.now

    event = LogStash::Event.new
    event.type = @typename

    logsource = "evita"
    timestamp = "Mar 16 00:01:25"
    message = "connect from camomile.cloud9.net[168.100.1.3]"
    program = "postfix/smtpd"
    pid = "1713"

    event.message = "#{timestamp} #{logsource} #{program}[#{pid}]: #{message}"

    check_interval = 1500
    1.upto(iterations).each do |i|
      event.fields.clear
      @filter.filter(event)
    end

    duration = Time.now - start
    max_duration = 10
    puts "filters/grok speed test; #{iterations} iterations: #{duration} seconds (#{"%.3f" % (iterations / duration)} per sec)"
    assert(duration < max_duration, "Should be able to do #{iterations} grok parses in less than #{max_duration} seconds, got #{duration} seconds")
  end # test_formats
end
