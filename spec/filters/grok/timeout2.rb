require "test_utils"
require "grok-pure"
require "timeout"

describe "grok known timeout failures" do
  extend LogStash::RSpec

  describe "user reported timeout" do
    config <<-'CONFIG'
      filter {
        grok { 
         match  => [ "@message", "%{SYSLOGBASE:ts1} \[\#\|%{TIMESTAMP_ISO8601:ts2}\|%{DATA} for %{PATH:url} = %{POSINT:delay} ms.%{GREEDYDATA}" ]
        }
      }
    CONFIG

    start = Time.now
    line = 'Nov 13 19:23:34 qa-api1 glassfish: [#|2012-11-13T19:23:25.604+0000|INFO|glassfish3.1.2|com.locusenergy.platform.messages.LocusMessage|_ThreadID=59;_ThreadName=Thread-2;|API TIMER - Cache HIT user: null for /kiosks/194/energyreadings/data?tz=America/New_York&fields=kwh&type=gen&end=2012-11-13T23:59:59&start=2010-12-16T00:00:00-05:00&gran=yearly = 5 ms.|#]'

    sample line do
      duration = Time.now - start
      insist { duration } < 0.03
    end
  end
end

__END__
