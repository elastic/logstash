require "test_utils"
require "logstash/filters/punct"

describe LogStash::Filters::Punct do
  extend LogStash::RSpec

  describe "all defaults" do
    config <<-CONFIG
      filter {
        punct { }
      }
    CONFIG

    sample "PHP Warning:  json_encode() [<a href='function.json-encode'>function.json-encode</a>]: Invalid UTF-8 sequence in argument in /data1/sinawap/code/weibov4_wap/control/h5/main/trends.php on line 233" do
      insist { subject["punct"] } == ":_()[<='.-'>.-</>]:-////_////."
    end
  end
end
