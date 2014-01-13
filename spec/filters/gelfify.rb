require "test_utils"
require "logstash/filters/gelfify"

describe LogStash::Filters::Gelfify do
  extend LogStash::RSpec

    SYSLOG_LEVEL_MAP = {
    0 => 3, # Emergency => FATAL
    1 => 5, # Alert     => WARN
    2 => 3, # Critical  => FATAL
    3 => 4, # Error     => ERROR
    4 => 5, # Warning   => WARN
    5 => 6, # Notice    => INFO
    6 => 6, # Informat. => INFO
    7 => 7  # Debug     => DEBUG
  }

  SYSLOG_LEVEL_MAP.each do |k,v|

    describe "gelfify #{k} to #{v}" do
      config <<-CONFIG
        filter {
          gelfify { }
        }
      CONFIG

      sample("severity" => k) do
        insist { subject["GELF_severity"] } == v
      end
    end

  end

end
