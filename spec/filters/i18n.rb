# encoding: utf-8
require "test_utils"
require "logstash/filters/i18n"

describe LogStash::Filters::I18n do
  extend LogStash::RSpec

  describe "transliterate" do
    config <<-CONFIG
      filter {
        i18n {
          transliterate => [ "transliterateme" ]
        }
      }
    CONFIG

    event = {
      "transliterateme" => [ "Ærøskøbing" ]
    }

    sample event do
      insist { subject["transliterateme"] } == [ "AEroskobing" ]
    end
  end
end
