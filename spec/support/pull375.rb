# encoding: utf-8

# This spec covers the question here:
# https://github.com/logstash/logstash/pull/375

require "test_utils"

describe "pull #375" do
  extend LogStash::RSpec
  describe  "kv after grok" do
    config <<-CONFIG
      filter {
        grok { pattern => "%{URIPATH:mypath}%{URIPARAM:myparams}" }
        kv { source => "myparams" field_split => "&?" }
      }
    CONFIG

    sample "/some/path?foo=bar&baz=fizz" do
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
    end
  end
end
