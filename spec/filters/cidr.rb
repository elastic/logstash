require "test_utils"
require "logstash/filters/cidr"

describe LogStash::Filters::CIDR do
  extend LogStash::RSpec

  describe "IPV4 match test" do
    config <<-CONFIG
      filter {
        cidr {
          address => [ "%{clientip}" ]
          network => [ "192.168.0.0/24" ]
          add_tag => [ "matched" ]
        }
      }
    CONFIG

    sample("clientip" => "192.168.0.30") do
      insist { subject["tags"] }.include?("matched") 
    end
  end

  describe "IPV4 non match" do
   config <<-CONFIG
       filter {
        cidr {
          address => [ "%{clientip}" ]
          network => [ "192.168.0.0/24" ]
          add_tag => [ "matched" ]
        }
      }
    CONFIG

    sample("clientip" => "123.52.122.33") do
       insist { subject["tags"] }.nil?
    end
  end

  describe "IPV6 match test" do
    config <<-CONFIG
      filter {
        cidr {
          address => [ "%{clientip}" ]
          network => [ "fe80::/64" ]
          add_tag => [ "matched" ]
        }
      }
    CONFIG

    sample("clientip" => "fe80:0:0:0:0:0:0:1") do
      insist { subject["tags"] }.include?("matched") 
    end
  end

  describe "IPV6 non match" do
   config <<-CONFIG
       filter {
        cidr {
          address => [ "%{clientip}" ]
          network => [ "fe80::/64" ]
          add_tag => [ "matched" ]
        }
      }
    CONFIG

    sample("clientip" => "fd82:0:0:0:0:0:0:1") do
       insist { subject["tags"] }.nil?
    end
  end

end
