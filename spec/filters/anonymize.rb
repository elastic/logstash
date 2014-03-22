# encoding: utf-8

require "test_utils"
require "logstash/filters/anonymize"

describe LogStash::Filters::Anonymize do
  extend LogStash::RSpec

  describe "anonymize ipaddress with IPV4_NETWORK algorithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          algorithm => "IPV4_NETWORK"
          key => 24
        }
      }
    CONFIG

    sample("clientip" => "233.255.13.44") do
      insist { subject["clientip"] } == "233.255.13.0"
    end
  end

  describe "anonymize string with MURMUR3 algorithm" do
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          algorithm => "MURMUR3"
          key => ""
        }
      }
    CONFIG

    sample("clientip" => "123.52.122.33") do
      insist { subject["clientip"] } == 1541804874
    end
  end

   describe "anonymize string with SHA1 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          key => "longencryptionkey"
          algorithm => 'SHA1'
        }
      }
    CONFIG

    sample("clientip" => "123.123.123.123") do
      insist { subject["clientip"] } == "fdc60acc4773dc5ac569ffb78fcb93c9630797f4"
    end
  end

  # HMAC-SHA224 isn't implemented in JRuby OpenSSL
  #describe "anonymize string with SHA224 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    #config <<-CONFIG
      #filter {
        #anonymize {
          #fields => ["clientip"]
          #key => "longencryptionkey"
          #algorithm => 'SHA224'
        #}
      #}
    #CONFIG

    #sample("clientip" => "123.123.123.123") do
      #insist { subject["clientip"] } == "5744bbcc4f64acb6a805b7fee3013a8958cc8782d3fb0fb318cec915"
    #end
  #end

  describe "anonymize string with SHA256 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          key => "longencryptionkey"
          algorithm => 'SHA256'
        }
      }
    CONFIG

    sample("clientip" => "123.123.123.123") do
      insist { subject["clientip"] } == "345bec3eff242d53b568916c2610b3e393d885d6b96d643f38494fd74bf4a9ca"
    end
  end

  describe "anonymize string with SHA384 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          key => "longencryptionkey"
          algorithm => 'SHA384'
        }
      }
    CONFIG

    sample("clientip" => "123.123.123.123") do
      insist { subject["clientip"] } == "22d4c0e8c4fbcdc4887d2038fca7650f0e2e0e2457ff41c06eb2a980dded6749561c814fe182aff93e2538d18593947a"
    end
  end

  describe "anonymize string with SHA512 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          key => "longencryptionkey"
          algorithm => 'SHA512'
        }
      }
    CONFIG

    sample("clientip" => "123.123.123.123") do
      insist { subject["clientip"] } == "11c19b326936c08d6c50a3c847d883e5a1362e6a64dd55201a25f2c1ac1b673f7d8bf15b8f112a4978276d573275e3b14166e17246f670c2a539401c5bfdace8"
    end
  end

  # HMAC-MD4 isn't implemented in JRuby OpenSSL
  #describe "anonymize string with MD4 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    #config <<-CONFIG
      #filter {
        #anonymize {
          #fields => ["clientip"]
          #key => "longencryptionkey"
          #algorithm => 'MD4'
        #}
      #}
    #CONFIG
#
    #sample("clientip" => "123.123.123.123") do
      #insist { subject["clientip"] } == "0845cb571ab3646e51a07bcabf05e33d"
    #end
  #end

  describe "anonymize string with MD5 alogrithm" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          key => "longencryptionkey"
          algorithm => 'MD5'
        }
      }
    CONFIG

    sample("clientip" => "123.123.123.123") do
      insist { subject["clientip"] } == "9336c879e305c9604a3843fc3e75948f"
    end
  end

  describe "Test field with multiple values" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        anonymize {
          fields => ["clientip"]
          key => "longencryptionkey"
          algorithm => 'MD5'
        }
      }
    CONFIG

    sample("clientip" => [ "123.123.123.123", "223.223.223.223" ]) do
      insist { subject["clientip"]} == [ "9336c879e305c9604a3843fc3e75948f", "7a6c66b8d3f42a7d650e3354af508df3" ]
    end
  end



end
