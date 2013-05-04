require "test_utils"
require "logstash/filters/geoip"

describe LogStash::Filters::GeoIP do
  extend LogStash::RSpec
  describe "defaults" do
    config <<-CONFIG
      filter {
        geoip { 
          source => "ip"
          database => "vendor/geoip/GeoLiteCity.dat"
        }
      }
    CONFIG

    sample({ "@fields" => { "ip" => "8.8.8.8" } }) do
      insist { subject }.include?("geoip")

      expected_fields = %w(ip country_code2 country_code3 country_name
                           continent_code region_name city_name postal_code
                           latitude longitude dma_code area_code timezone)
      expected_fields.each do |f|
        insist { subject["geoip"] }.include?(f)
      end
    end

    sample({ "@fields" => { "ip" => "127.0.0.1" } }) do
      # assume geoip fails on localhost lookups
      reject { subject }.include?("geoip")
    end
  end
end
