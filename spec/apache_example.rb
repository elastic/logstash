require "test_utils"

describe "apache common log format" do
  extend LogStash::RSpec
  config <<-CONFIG
    filter {
      grok {
        pattern => "%{COMBINEDAPACHELOG}"
      }
    }
  CONFIG

  sample '198.151.8.4 - - [29/Aug/2012:20:17:38 -0400] "GET /favicon.ico HTTP/1.1" 200 3638 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:14.0) Gecko/20100101 Firefox/14.0.1"' do
    it "should not have tag _grokparsefailure" do
      reject { subject["@tags"] }.include?("_grokparsefailure")
      insist { subject }.include?("agent")
      insist { subject }.include?("bytes")
      insist { subject }.include?("clientip")
      insist { subject }.include?("httpversion")
      insist { subject }.include?("timestamp")
      insist { subject }.include?("verb")
      insist { subject }.include?("response")
      insist { subject }.include?("request")

      insist { subject["clientip"] } == "198.151.8.4"
    end
  end
end
