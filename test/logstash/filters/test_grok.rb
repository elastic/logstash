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
    config "pattern" => [ "(?:hello|world) %{NUMBER}" ],
           "named_captures_only" => "false"

    event = LogStash::Event.new
    event.type = @typename
    event.message = [ "hello 12345", "world 23456" ]

    @filter.filter(event)
    $stderr.puts event.to_hash.inspect
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
    config "pattern" => [ "%{FIZZLE=\\d+}" ], "named_captures_only" => "false"

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
    config "rum" => [ "%{FIZZLE=\\d+}" ], "named_captures_only" => "false"

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
    config "rum" => [ "%{FIZZLE=\\d+}" ], "pattern" => "%{WORD}",
      "break_on_match" => "false", "named_captures_only" => "false"

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
  end # def test_grok_field_name_attribute

  test "adding fields on match" do
    config "str" => "test",
           "add_field" => ["new_field", "new_value"]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "test"
    @filter.filter(event)
    assert_equal(["new_value"], event["new_field"])
  end # adding fields on match

  test "should not add fields if match fails" do
    config "str" => "test",
           "add_field" => ["new_field", "new_value"]

    event = LogStash::Event.new
    event.type = @typename
    event["str"] = "fizzle"
    @filter.filter(event)
    assert_equal(nil, event["new_field"],
                "Grok should not add fields on failed matches")
  end # should not add fields if match fails

  test "drop empty fields by default" do
    config "pattern" => "1=%{WORD:foo1} *(2=%{WORD:foo2})?"

    event = LogStash::Event.new
    event.type = @typename
    event.message = "1=test"
    @filter.filter(event)
    assert_equal(["test"], event["foo1"])
    assert_equal(nil, event["foo2"])
  end

  test "keep empty fields" do
    config "pattern" => "1=%{WORD:foo1} *(2=%{WORD:foo2})?",
           "keep_empty_captures" => "true"

    event = LogStash::Event.new
    event.type = @typename
    event.message = "1=test"
    @filter.filter(event)
    assert_equal(["test"], event["foo1"])
    assert_equal([], event["foo2"])
  end

  test "named_captures_only set to false" do
    config "pattern" => "Hello %{WORD}. %{WORD:foo}", "named_captures_only" => "false"

    event = LogStash::Event.new
    event.type = @typename
    event.message = "Hello World, yo!"
    @filter.filter(event)
    assert(event.fields.include?("WORD"),
           "The event must have the 'WORD' field")
    assert(event.fields.include?("foo"),
           "The event must have the 'foo' field")
    assert_equal("World", event.fields["WORD"].first)
    assert_equal("yo", event.fields["foo"].first)
  end
end # tests for LogStash::Filters::Grok
