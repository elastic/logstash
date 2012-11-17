require "test_utils"

describe "parse mysql slow query log" do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      grep {
        # Drop the '# Time:' lines since they only appear when the 'time'
        # changes and are omitted otherwise. Further, there's always (from what
        # I have seen) a 'SET timestamp=123456789' line in each query event, so
        # I use that as the timestamp instead.
        #
        # mysql logs are fucked up, so this is pretty much best effort.
        match => [ "@message", "^# Time: " ]
        negate => true
      }

      grok {
        singles => true
        pattern => [
          "^# User@Host: %{USER:user}\[[^\]]+\] @ %{HOST:host} \[%{IP:ip}?]",
          "^# Query_time: %{NUMBER:duration:float} \s*Lock_time: %{NUMBER:lock_wait:float} \s*Rows_sent: %{NUMBER:results:int} \s*Rows_examined: %{NUMBER:scanned:int}",
          "^SET timestamp=%{NUMBER:timestamp};"
        ]
      }

      multiline {
        pattern => "^# User@Host: "
        negate => true
        what => previous
      }

      date {
        timestamp => UNIX
      }

      mutate {
        remove => "timestamp"
      }
    }
  CONFIG

  lines = <<-'MYSQL_SLOW_LOGS'
# Time: 121004  6:00:27
# User@Host: someuser[someuser] @ db.example.com [1.2.3.4]
# Query_time: 0.018143  Lock_time: 0.000042 Rows_sent: 237  Rows_examined: 286
use somedb;
SET timestamp=1349355627;
SELECT option_name, option_value FROM wp_options WHERE autoload = 'yes';
MYSQL_SLOW_LOGS

  sample lines.split("\n") do
    insist { subject.size } == 1 # 1 event
    event = subject.first
    insist { event.message.split("\n").size } == 5 # 5 lines

    lines.split("\n")[1..5].each_with_index do |line, i|
      insist { event.message.split("\n")[i] } == line
    end

    insist { event["user"] } == "someuser"
    insist { event["host"] } == "db.example.com"
    insist { event["ip"] } == "1.2.3.4"
    insist { event["duration"] } == 0.018143
    insist { event["lock_wait"] } == 0.000042
    insist { event["results"] } == 237
    insist { event["scanned"] } == 286
  end
end
