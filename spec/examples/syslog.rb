# encoding: utf-8

require "test_utils"

describe "parse syslog", :if => RUBY_ENGINE == "jruby" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      grok {
          type => "syslog"
          singles => true
          pattern => [ "<%{POSINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{PROG:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" ]
          add_field => [ "received_at", "%{@timestamp}" ]
          add_field => [ "received_from", "%{source_host}" ]
      }
      syslog_pri {
          type => "syslog"
      }
      date {
          type => "syslog"
          match => ["syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
      }
      mutate {
          type => "syslog"
          exclude_tags => "_grokparsefailure"
          replace => [ "source_host", "%{syslog_hostname}" ]
          replace => [ "message", "%{syslog_message}" ]
      }
      mutate {
          type => "syslog"
          remove => [ "syslog_hostname", "syslog_message", "syslog_timestamp" ]
      }
    }
  CONFIG

  sample("message" => "<164>Oct 26 15:19:25 1.2.3.4 %ASA-4-106023: Deny udp src DRAC:10.1.2.3/43434 dst outside:192.168.0.1/53 by access-group \"acl_drac\" [0x0, 0x0]", "type" => "syslog") do
    insist { subject["type"] } == "syslog"
    insist { subject["tags"] }.nil?
    insist { subject["syslog_pri"] } == "164"
  end

  # Single digit day
  sample("message" => "<164>Oct  6 15:19:25 1.2.3.4 %ASA-4-106023: Deny udp src DRAC:10.1.2.3/43434 dst outside:192.168.0.1/53 by access-group \"acl_drac\" [0x0, 0x0]", "type" => "syslog") do
    insist { subject["type"] } == "syslog"
    insist { subject["tags"] }.nil?
    insist { subject["syslog_pri"] } == "164"
    #insist { subject.timestamp } == "2012-10-26T15:19:25.000Z"
  end
end
