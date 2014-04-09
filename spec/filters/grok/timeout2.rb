require "test_utils"
require "grok-pure"
require "timeout"

describe "grok known timeout failures" do
  extend LogStash::RSpec

  describe "user reported timeout" do
    config <<-'CONFIG'
      filter {
        grok {
         match  => [ "message", "%{SYSLOGBASE:ts1} \[\#\|%{TIMESTAMP_ISO8601:ts2}\|%{DATA} for %{PATH:url} = %{POSINT:delay} ms.%{GREEDYDATA}" ]
        }
      }
    CONFIG

    start = Time.now
    line = 'Nov 13 19:23:34 qa-api1 glassfish: [#|2012-11-13T19:23:25.604+0000|INFO|glassfish3.1.2|com.locusenergy.platform.messages.LocusMessage|_ThreadID=59;_ThreadName=Thread-2;|API TIMER - Cache HIT user: null for /kiosks/194/energyreadings/data?tz=America/New_York&fields=kwh&type=gen&end=2012-11-13T23:59:59&start=2010-12-16T00:00:00-05:00&gran=yearly = 5 ms.|#]'

    sample line do
      duration = Time.now - start
      # insist { duration } < 0.03  #TODO refactor performance tests
    end
  end

  describe "user reported timeout" do
    config <<-'CONFIG'
      filter {
        grok {
          pattern => [
            "%{DATA:http_host} %{IPORHOST:clientip} %{USER:ident} %{USER:http_auth} \[%{HTTPDATE:http_timestamp}\] \"%{WORD:http_method} %{DATA:http_request} HTTP/%{NUMBER:http_version}\" %{NUMBER:http_response_code} (?:%{NUMBER:bytes}|-) \"(?:%{URI:http_referrer}|-)\" %{QS:http_user_agent} %{QS:http_x_forwarded_for} %{USER:ssl_chiper} %{NUMBER:request_time} (?:%{DATA:gzip_ratio}|-) (?:%{DATA:upstream}|-) (?:%{NUMBER:upstream_time}|-) (?:%{WORD:geoip_country}|-)",
            "%{DATA:http_host} %{IPORHOST:clientip} %{USER:ident} %{USER:http_auth} \[%{HTTPDATE:http_timestamp}\] \"%{WORD:http_method} %{DATA:http_request} HTTP/%{NUMBER:http_version}\" %{NUMBER:http_response_code} (?:%{NUMBER:bytes}|-) \"(?:%{URI:http_referrer}|-)\" %{QS:http_user_agent} %{QS:http_x_forwarded_for} %{USER:ssl_chiper} %{NUMBER:request_time} (?:%{DATA:gzip_ratio}|-) (?:%{DATA:upstream}|-) (?:%{NUMBER:upstream_time}|-)"
          ]
        }
      }
    CONFIG

    #TODO fixme

    # start = Time.now
    # sample 'www.example.com 10.6.10.13 - - [09/Aug/2012:16:19:39 +0200] "GET /index.php HTTP/1.1" 403 211 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12" "-" - 0.019 - 10.6.10.12:81 0.002 US' do
    #   duration = Time.now - start
    #   # insist { duration } < 1  #TODO refactor performance tests
    #   puts( subject["tags"])
    #   reject { subject["tags"] }.include?("_grokparsefailure")
    #   insist { subject["geoip_country"] } == ["US"]
    # end


    # sample 'www.example.com 10.6.10.13 - - [09/Aug/2012:16:19:39 +0200] "GET /index.php HTTP/1.1" 403 211 "-" "Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.8.1.12) Gecko/20080201 Firefox/2.0.0.12" "-" - 0.019 - 10.6.10.12:81 0.002 -' do
    #   duration = Time.now - start
    #   # insist { duration } < 1 #TODO refactor performance tests
    #   reject { subject["tags"] }.include?("_grokparsefailure")
    #   insist { subject["geoip_country"].nil? } == true
    # end
  end
end

__END__
