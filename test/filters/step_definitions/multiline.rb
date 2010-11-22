$:.unshift("#{File.dirname(__FILE__)}/../../../lib")
require "logstash/event"
require "logstash/filters/multiline"
require "test/unit"

include Test::Unit::Assertions

Given /^a multiline pattern of "([^"]*)"$/ do |pattern|
  @pattern = pattern
end

Given /^a multiline what of "([^"]*)"$/ do |what|
  @what = what
end

When /^the inputs are$/ do |table|
  @eventtype = "testtype"
  @multiline = LogStash::Filters::Multiline.new({
    @eventtype => {
      "pattern" => @pattern,
      "what" => @what
    }
  })
  @multiline.register

  @events = []
  @source = "file:///test"
  table.raw.each do |row|
    # We are whitespace sensitive, and cucumber trims whitespace on
    # table data sets, so let's hack around it with quotes.
    message = row.first.gsub(/^"/, "").gsub(/"$/, "")
    event = LogStash::Event.new({})
    event.message = message
    event.source = @source
    event.type = @eventtype
    @multiline.filter(event)

    if !event.cancelled?
      @events << event
    end
  end

  lastevent = @multiline.flush(@source, @eventtype)
  if lastevent
    @events << lastevent
  end
end

Then /^the event message should be$/ do |table|
  # table is a Cucumber::Ast::Table
  assert_equal(table.raw.length, @events.length,
               "Should have #{table.raw.length} events, got #{@events.length}")
  event_idx = 0
  table.raw.each do |row|
    message = row.first.gsub(/\\n/, "\n")
    assert_equal(message, @events[event_idx].message, "Wrong message")
    event_idx += 1
  end
end
1
