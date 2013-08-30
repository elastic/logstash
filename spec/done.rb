require "test_utils"

describe "done" do
  extend LogStash::RSpec

  #if done works, ip sample should pass and not fail at host test
  config <<-CONFIG
    filter {
      grok {
        pattern => "%{IP:ipaddress}"
        singles => true
        done => true
      }
      grok {
        pattern => "%{HOST:hostname}"
        singles => true
      }
    }
  CONFIG

  sample "10.0.0.0" do
    insist { subject["ipaddress"] } == "10.0.0.0"
    insist { subject["hostname"] }.nil?
    insist { subject["tags"] }.nil?
  end

  sample "www.example.org" do
    insist { subject["ipaddress"] }.nil?
    insist { subject["hostname"] } == "www.example.org"
    insist { subject["tags"] }.include?("_grokparsefailure")
  end
end

