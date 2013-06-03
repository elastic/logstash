require "test_utils"
require "logstash/filters/translate"

describe LogStash::Filters::Translate do
  extend LogStash::RSpec

  describe "exact translation" do
    config <<-CONFIG
      filter {
        translate {
          field       => "status"
          destination => "translation"
          dictionary  => [ "200", "OK",
                           "300", "Redirect",
                           "400", "Client Error",
                           "500", "Server Error" ]
          exact       => true
          regex       => false
        }
      }
    CONFIG

    sample("status" => 200) do
      insist { subject["translation"] } == "OK"
    end
  end

  describe "multi translation" do
    config <<-CONFIG
      filter {
        translate {
          field       => "status"
          destination => "translation"
          dictionary  => [ "200", "OK",
                           "300", "Redirect",
                           "400", "Client Error",
                          "500", "Server Error" ]
          exact       => false
          regex       => false
        }
      }
    CONFIG

    sample("status" => "200 & 500") do
      insist { subject["translation"] } == "OK & Server Error"
    end
  end

  describe "regex translation" do
    config <<-CONFIG
      filter {
        translate {
          field       => "status"
          destination => "translation"
          dictionary  => [ "^2[0-9][0-9]$", "OK",
                           "^3[0-9][0-9]$", "Redirect",
                           "^4[0-9][0-9]$", "Client Error",
                           "^5[0-9][0-9]$", "Server Error" ]
          exact       => true
          regex       => true
        }
      }
    CONFIG

    sample("status" => "200") do
      insist { subject["translation"] } == "OK"
    end
  end

end
