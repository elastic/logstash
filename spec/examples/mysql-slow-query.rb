require "test_utils"

# Skip until we convert this to use multiline codec
describe "parse mysql slow query log", :if => false do
  extend LogStash::RSpec

  config <<-'CONFIG'
    filter {
      grep {
        # Drop the '# Time:' lines since they only appear when the 'time'
        # changes and are omitted otherwise. Further, there's always (from what
        # I have seen) a 'SET timestamp=123456789' line in each query event, so
        # I use that as the timestamp instead.
        #
        # mysql logs are messed up, so this is pretty much best effort.
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
        match => ["timestamp", UNIX]
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
    reject { subject }.is_a? Array # 1 event expected
    insist { subject.message.split("\n").size } == 5 # 5 lines

    lines.split("\n")[1..5].each_with_index do |line, i|
      insist { subject.message.split("\n")[i] } == line
    end

    insist { subject["user"] } == "someuser"
    insist { subject["host"] } == "db.example.com"
    insist { subject["ip"] } == "1.2.3.4"
    insist { subject["duration"] } == 0.018143
    insist { subject["lock_wait"] } == 0.000042
    insist { subject["results"] } == 237
    insist { subject["scanned"] } == 286
  end
end
