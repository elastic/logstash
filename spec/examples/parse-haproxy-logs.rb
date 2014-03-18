# encoding: utf-8

require "test_utils"

describe "haproxy httplog format" do
  extend LogStash::RSpec

  # The logstash config goes here.
  # At this time, only filters are supported.
  config <<-CONFIG
  filter {
    grok {
      pattern => "%{HAPROXYHTTP}"
    }
  }
  CONFIG
  # Here we provide a sample log event for the testing suite.
  #
  # Any filters you define above will be applied the same way the logstash
  # agent performs. Inside the 'sample ... ' block the 'subject' will be
  # a LogStash::Event object for you to inspect and verify for correctness.
  # HAPROXYHTTP %{SYSLOGTIMESTAMP:syslog_timestamp} %{IPORHOST:syslog_server} %{SYSLOGPROG}: %{IP:client_ip}:%{INT:client_port} \[%{HAPROXYDATE:accept_date}\] %{NOTSPACE:frontend_name} %{NOTSPACE:backend_name}/%{NOTSPACE:server_name} %{INT:time_request}/%{INT:time_queue}/%{INT:time_backend_connect}/%{INT:time_backend_response}/%{NOTSPACE:time_duration} %{INT:http_status_code} %{NOTSPACE:bytes_read} %{DATA:captured_request_cookie} %{DATA:captured_response_cookie} %{NOTSPACE:termination_state} %{INT:actconn}/%{INT:feconn}/%{INT:beconn}/%{INT:srvconn}/%{NOTSPACE:retries} %{INT:srv_queue}/%{INT:backend_queue} (\{%{HAPROXYCAPTUREDREQUESTHEADERS}\})?( )?(\{%{HAPROXYCAPTUREDRESPONSEHEADERS}\})?( )?"(<BADREQ>|(%{WORD:http_verb} (%{URIPROTO:http_proto}://)?(?:%{USER:http_user}(?::[^@]*)?@)?(?:%{URIHOST:http_host})?(?:%{URIPATHPARAM:http_request})?( HTTP/%{NUMBER:http_version})?))?"

  sample 'Feb  6 12:14:14 localhost haproxy[14389]: 10.0.1.2:33317 [06/Feb/2009:12:14:14.655] http-in static/srv1 10/0/30/69/109 200 2750 - - ---- 1/1/1/1/0 0/0 {1wt.eu} {} "GET /index.html HTTP/1.1"' do

    # These 'insist' and 'reject' calls use my 'insist' rubygem.
    # See http://rubydoc.info/gems/insist for more info.

    # Require that grok does not fail to parse this event.
    insist { subject["tags"] }.nil?


    # Ensure that grok captures certain expected fields.
    insist { subject }.include?("syslog_timestamp")
    insist { subject }.include?("syslog_server")
    insist { subject }.include?("program")
    insist { subject }.include?("pid")
    insist { subject }.include?("client_ip")
    insist { subject }.include?("client_port")
    insist { subject }.include?("accept_date")
    insist { subject }.include?("haproxy_monthday")
    insist { subject }.include?("haproxy_month")
    insist { subject }.include?("haproxy_year")
    insist { subject }.include?("haproxy_time")
    insist { subject }.include?("haproxy_hour")
    insist { subject }.include?("haproxy_minute")
    insist { subject }.include?("haproxy_second")
    insist { subject }.include?("haproxy_milliseconds")
    insist { subject }.include?("frontend_name")
    insist { subject }.include?("backend_name")
    insist { subject }.include?("server_name")
    insist { subject }.include?("time_request")
    insist { subject }.include?("time_queue")
    insist { subject }.include?("time_backend_connect")
    insist { subject }.include?("time_backend_response")
    insist { subject }.include?("time_duration")
    insist { subject }.include?("http_status_code")
    insist { subject }.include?("bytes_read")
    insist { subject }.include?("captured_request_cookie")
    insist { subject }.include?("captured_response_cookie")
    insist { subject }.include?("termination_state")
    insist { subject }.include?("actconn")
    insist { subject }.include?("feconn")
    insist { subject }.include?("beconn")
    insist { subject }.include?("srvconn")
    insist { subject }.include?("retries")
    insist { subject }.include?("srv_queue")
    insist { subject }.include?("backend_queue")
    insist { subject }.include?("captured_request_headers")
    insist { subject }.include?("http_verb")
    insist { subject }.include?("http_request")
    insist { subject }.include?("http_version")

#    # Ensure that those fields match expected values from the event.

    insist{ subject["syslog_timestamp"] } == "Feb  6 12:14:14"
    insist{ subject["syslog_server"] } == "localhost"
    insist{ subject["program"] } == "haproxy"
    insist{ subject["pid"] } == "14389"
    insist{ subject["client_ip"] } == "10.0.1.2"
    insist{ subject["client_port"] } == "33317"
    insist{ subject["accept_date"] } == "06/Feb/2009:12:14:14.655"
    insist{ subject["haproxy_monthday"] } == "06"
    insist{ subject["haproxy_month"] } == "Feb"
    insist{ subject["haproxy_year"] } == "2009"
    insist{ subject["haproxy_time"] } == "12:14:14"
    insist{ subject["haproxy_hour"] } == "12"
    insist{ subject["haproxy_minute"] } == "14"
    insist{ subject["haproxy_second"] } == "14"
    insist{ subject["haproxy_milliseconds"] } == "655"
    insist{ subject["frontend_name"] } == "http-in"
    insist{ subject["backend_name"] } == "static"
    insist{ subject["server_name"] } == "srv1"
    insist{ subject["time_request"] } == "10"
    insist{ subject["time_queue"] } == "0"
    insist{ subject["time_backend_connect"] } == "30"
    insist{ subject["time_backend_response"] } == "69"
    insist{ subject["time_duration"] } == "109"
    insist{ subject["http_status_code"] } == "200"
    insist{ subject["bytes_read"] } == "2750"
    insist{ subject["captured_request_cookie"] } == "-"
    insist{ subject["captured_response_cookie"] } == "-"
    insist{ subject["termination_state"] } == "----"
    insist{ subject["actconn"] } == "1"
    insist{ subject["feconn"] } == "1"
    insist{ subject["beconn"] } == "1"
    insist{ subject["srvconn"] } == "1"
    insist{ subject["retries"] } == "0"
    insist{ subject["srv_queue"] } == "0"
    insist{ subject["backend_queue"] } == "0"
    insist{ subject["captured_request_headers"] } == "1wt.eu"
    insist{ subject["http_verb"] } == "GET"
    insist{ subject["http_request"] } == "/index.html"
    insist{ subject["http_version"] } == "1.1"
  end

end
