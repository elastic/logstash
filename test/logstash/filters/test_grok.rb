require "rubygems"
require File.join(File.dirname(__FILE__), "..", "minitest")

require "logstash"
require "logstash/loadlibs"
require "logstash/filters"
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

    #p :config => cfg
    #p :filter => @filter
    @filter = LogStash::Filters::Grok.new(cfg)
    @filter.register
  end

  test "normal grok" do
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
                 "Expected field 'logsource' to be [#{logsource.inspect}], " \
                 "is #{event.fields["logsource"].inspect}")

    assert_equal(event.fields["timestamp"], [timestamp],
                 "Expected field 'timestamp' to be [#{timestamp.inspect}], " \
                 "is #{event.fields["timestamp"].inspect}")

    assert_equal(event.fields["message"], [message], 
                 "Expected field 'message' to be ['#{message.inspect}'], " \
                 "is #{event.fields["message"].inspect}")

    assert_equal(event.fields["program"], [program], 
                 "Expected field 'program' to be ['#{program.inspect}'], " \
                 "is #{event.fields["program"].inspect}")

    assert_equal(event.fields["pid"], [pid], 
                 "Expected field 'pid' to be ['#{pid.inspect}'], " \
                 "is #{event.fields["pid"].inspect}")
  end # test normal

  test "parsing an event with multiple messages (array of strings)" do
    config "pattern" => [ "(?:hello|world) %{NUMBER}" ]
    
    event = LogStash::Event.new
    event.type = @typename
    event.message = [ "hello 12345", "world 23456" ]

    @filter.filter(event)
    assert_equal(event.fields["NUMBER"].sort, ["12345", "23456"])
  end # parsing event with multiple messages

  test "performance" do
    config "pattern" => [ "%{SYSLOGLINE}" ]
    puts "Doing performance test"

    iterations = 50000

    start = Time.now
    event = LogStash::Event.new
    event.type = @typename

    logsource = "evita"
    timestamp = "Mar 16 00:01:25"
    message = "connect from camomile.cloud9.net[168.100.1.3]"
    program = "postfix/smtpd"
    pid = "1713"

    event.message = "#{timestamp} #{logsource} #{program}[#{pid}]: #{message}"

    check_interval = 997
    1.upto(iterations).each do |i|
      event.fields.clear
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

  test "grok pattern type coercion to integer" do
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
  end # test int type coercion

  test "pattern type coercion to float" do
    config "pattern" => [ "%{NUMBER:foo:float}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = 3.1415
    event.message = "#{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["foo"].first.class,
                 "Expected field 'foo' to be of type #{expect.class.name} " \
                 "but got #{event.fields["foo"].first.class.name}")
    assert_equal([expect], event.fields["foo"],
                 "Expected field 'foo' to be [#{expect.inspect}], " \
                 "is #{event.fields["foo"].inspect}")
  end # test float coercion

  test "in-line pattern definitions" do
    config "pattern" => [ "%{FIZZLE=\\d+}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = "1234"
    event.message = "hello #{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["FIZZLE"].first.class,
                 "Expected field 'FIZZLE' to be of type #{expect.class.name} " \
                 "but got #{event.fields["FIZZLE"].first.class.name}")
    assert_equal([expect], event.fields["FIZZLE"],
                 "Expected field 'FIZZLE' to be [#{expect.inspect}], " \
                 "is #{event.fields["FIZZLE"].inspect}")
  end # test in-line definitions

  test "processing fields other than the @message" do
    config "rum" => [ "%{FIZZLE=\\d+}" ]
    
    event = LogStash::Event.new
    event.type = @typename

    expect = "1234"
    event.fields["rum"] = "hello #{expect}"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["FIZZLE"].first.class,
                 "Expected field 'FIZZLE' to be of type #{expect.class.name}, " \
                 "but got #{event.fields["FIZZLE"].first.class.name}")
    assert_equal([expect], event.fields["FIZZLE"],
                 "Expected field 'FIZZLE' to be [#{expect.inspect}], " \
                 "is #{event.fields["FIZZLE"].inspect}")
  end # test processing custom fields

  test "parsing custom fields and default @message" do
    config "rum" => [ "%{FIZZLE=\\d+}" ], "pattern" => "%{WORD}", "break_on_match" => "false"
    
    event = LogStash::Event.new
    event.type = @typename

    expect = "1234"
    event.fields["rum"] = "hello #{expect}"
    event.message = "something fizzle"

    @filter.filter(event)
    assert_equal(expect.class, event.fields["FIZZLE"].first.class,
                 "Expected field 'FIZZLE' to be of type #{expect.class.name} " \
                 "but got #{event.fields["FIZZLE"].first.class.name}")
    assert_equal([expect], event.fields["FIZZLE"],
                 "Expected field 'FIZZLE' to be [#{expect.inspect}], is " \
                 "#{event.fields["FIZZLE"].inspect}")
    assert_equal(["something"], event.fields["WORD"],
                 "Expected field 'WORD' to be ['something'], is " \
                 "#{event.fields["WORD"].inspect}")
  end # parsing custom fields + default @message
end # testing LogStash::Filters::Grok
