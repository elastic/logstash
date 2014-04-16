# encoding: utf-8

require "test_utils"

describe "apache common log format", :if => RUBY_ENGINE == "jruby" do
  extend LogStash::RSpec

  # The logstash config goes here.
  # At this time, only filters are supported.
  config <<-CONFIG
    filter {
      grok {
        pattern => "%{COMBINEDAPACHELOG}"
        singles => true
      }
      date {
        match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss Z"]
        locale => "en"
      }
    }
  CONFIG

  # Here we provide a sample log event for the testing suite.
  #
  # Any filters you define above will be applied the same way the logstash
  # agent performs. Inside the 'sample ... ' block the 'subject' will be
  # a LogStash::Event object for you to inspect and verify for correctness.
  sample '198.151.8.4 - - [29/Aug/2012:20:17:38 -0400] "GET /favicon.ico HTTP/1.1" 200 3638 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1"' do

    # These 'insist' and 'reject' calls use my 'insist' rubygem.
    # See http://rubydoc.info/gems/insist for more info.

    # Require that grok does not fail to parse this event.
    insist { subject["tags"] }.nil?

    # Ensure that grok captures certain expected fields.
    insist { subject }.include?("agent")
    insist { subject }.include?("bytes")
    insist { subject }.include?("clientip")
    insist { subject }.include?("httpversion")
    insist { subject }.include?("timestamp")
    insist { subject }.include?("verb")
    insist { subject }.include?("response")
    insist { subject }.include?("request")

    # Ensure that those fields match expected values from the event.
    insist { subject["clientip"] } == "198.151.8.4"
    insist { subject["timestamp"] } == "29/Aug/2012:20:17:38 -0400"
    insist { subject["verb"] } == "GET"
    insist { subject["request"] } == "/favicon.ico"
    insist { subject["httpversion"] } == "1.1"
    insist { subject["response"] } == "200"
    insist { subject["bytes"] } == "3638"
    insist { subject["referrer"] } == '"-"'
    insist { subject["agent"] } == "\"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1\""

    # Verify date parsing
    insist { subject.timestamp } == Time.iso8601("2012-08-30T00:17:38.000Z")
  end

  sample '61.135.248.195 - - [26/Sep/2012:11:49:20 -0400] "GET /projects/keynav/ HTTP/1.1" 200 18985 "" "Mozilla/5.0 (compatible; YodaoBot/1.0; http://www.yodao.com/help/webmaster/spider/; )"' do
    insist { subject["tags"] }.nil?
    insist { subject["clientip"] } == "61.135.248.195"
  end

  sample '72.14.164.185 - - [25/Sep/2012:12:05:02 -0400] "GET /robots.txt HTTP/1.1" 200 - "www.brandimensions.com" "BDFetch"' do
    insist { subject["tags"] }.nil?
  end
end
