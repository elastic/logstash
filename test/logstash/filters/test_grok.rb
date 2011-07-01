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
    p :config => cfg, :id => @filter.object_id
    p :fizzle => @filter.pattern
    @filter.register
    #p :newfilter => @filter
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

  def test_grok_multiple_message
    test_name "groknormal"
    config "pattern" => [ "(?:hello|world) %{NUMBER}" ]
    
    event = LogStash::Event.new
    event.type = @typename
    event.message = [ "hello 12345", "world 23456" ]

    @filter.filter(event)
    assert_equal(event.fields["NUMBER"].sort, ["12345", "23456"])
  end # def test_grok_multiple_message

  def test_speed
    test_name "grokspeed"
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

  def test_grok_type_hinting_int
    test_name "groktypehinting_int"
    config "pattern" => [ "%{NUMBER:foo:int}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = 12345
    event.message = "#{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["foo"].first.class,
                 "Expected field 'foo' to be of type #{expect.class.name} " \
                 "but got #{event.fields["foo"].first.class.name}")
    assert_equal([expect], event.fields["foo"],
                 "Expected field 'foo' to be [#{expect.inspect}], is " \
                 "#{event.fields["expect"].inspect}")
  end # def test_grok_type_hinting_int

  def test_grok_type_hinting_float
    test_name "groktypehinting_float"
    config "pattern" => [ "%{NUMBER:foo:float}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = 3.1415
    event.message = "#{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["foo"].first.class, "Expected field 'foo' to be of type #{expect.class.name} but got #{event.fields["foo"].first.class.name}")
    assert_equal([expect], event.fields["foo"], "Expected field 'foo' to be [#{expect.inspect}], is #{event.fields["expect"].inspect}")
  end # def test_grok_type_hinting_float

  def test_grok_inline_define
    test_name "grok_inline_define"
    config "pattern" => [ "%{FIZZLE=\\d+}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = "1234"
    event.message = "hello #{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["FIZZLE"].first.class, "Expected field 'FIZZLE' to be of type #{expect.class.name} but got #{event.fields["FIZZLE"].first.class.name}")
    assert_equal([expect], event.fields["FIZZLE"], "Expected field 'FIZZLE' to be [#{expect.inspect}], is #{event.fields["expect"].inspect}")
  end # def test_grok_type_hinting_float

  def test_grok_field_name_attribute
    test_name "grok_field_name_attribute"
    config "rum" => [ "%{FIZZLE=\\d+}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = "1234"
    event.fields["rum"] = "hello #{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["FIZZLE"].first.class, "Expected field 'FIZZLE' to be of type #{expect.class.name} but got #{event.fields["FIZZLE"].first.class.name}")
    assert_equal([expect], event.fields["FIZZLE"], "Expected field 'FIZZLE' to be [#{expect.inspect}], is #{event.fields["expect"].inspect}")
  end # def test_grok_type_hinting_float
end
