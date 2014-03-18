# encoding: utf-8

require "test_utils"

describe "fail2ban logs", :if => RUBY_ENGINE == "jruby"  do
  extend LogStash::RSpec

  # The logstash config goes here.
  # At this time, only filters are supported.
  config <<-CONFIG
    filter {
      grok {
        pattern => "^%{TIMESTAMP_ISO8601:timestamp} fail2ban\.actions: %{WORD:level} \\[%{WORD:program}\\] %{WORD:action} %{IP:ip}"
        singles => true
      }
      date {
        match => [ "timestamp", "yyyy-MM-dd HH:mm:ss,SSS" ]
      }
      mutate {
        remove => timestamp
      }
    }
  CONFIG

  sample "2013-06-28 15:10:59,891 fail2ban.actions: WARNING [ssh] Ban 95.78.163.5" do
    insist { subject["program"] } == "ssh"
    insist { subject["action"] } == "Ban"
    insist { subject["ip"] } == "95.78.163.5"
  end
end
