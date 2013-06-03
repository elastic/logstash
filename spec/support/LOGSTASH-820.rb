# encoding: utf-8
# This spec covers the question here:
# https://logstash.jira.com/browse/LOGSTASH-820

require "test_utils"

describe "LOGSTASH-820" do
  extend LogStash::RSpec
  describe  "grok with unicode" do
    config <<-CONFIG
      filter {
        grok {
          #pattern => "<%{POSINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{PROG:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}"
          pattern => "<%{POSINT:syslog_pri}>%{SPACE}%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{PROG:syslog_program}(:?)(?:\\[%{GREEDYDATA:syslog_pid}\\])?(:?) %{GREEDYDATA:syslog_message}"
        }
      }
    CONFIG

    sample "<22>Jan  4 07:50:46 mailmaster postfix/policy-spf[9454]: : SPF permerror (Junk encountered in record 'v=spf1 mx a:mail.domain.no ip4:192.168.0.4 �all'): Envelope-from: email@domain.no" do
      insist { subject["tags"] }.nil?
      insist { subject["syslog_pri"] } == "22"
      insist { subject["syslog_program"] } == "postfix/policy-spf"
    end
  end
end
