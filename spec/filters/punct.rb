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

    sample "PHP Warning:  json_encode() [<a href='function.json-encode'>function.json-encode</a>]: Invalid UTF-8 sequence in argument in /var/www/htdocs/test.php on line 233" do
      insist { subject["punct"] } == ":_()[<='.-'>.-</>]:-////."
    end
  end
end
