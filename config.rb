require 'lib/logs'
require 'lib/log/json'
require 'lib/log/text'

include LogStash

$logs = Logs.new

# === define & register your logs below here
log = Log::TextLog.new({:type => "httpd-access",
                        :grok_patterns => ["%{COMBINEDAPACHELOG}"],
                        :date_key => "timestamp",
                        :date_format => "%d/%b/%Y:%H:%M:%S %Z",
})
$logs.register log

log = Log::JsonLog.new({:type => "glu",
                        :date_key => "timestamp",
                        :date_format => "%Y-%m-%dT%H:%M:%S",
                        :line_format => "<%= entry['timestamp'] %> | <%= entry['level'] %> | <%= entry['context/sessionKey'] %> | <%= entry['sourceHostName'] %> | <%= entry['context/componentName'] %> | <%= entry['message'] %>",
})
$logs.register log

log = Log::TextLog.new({:type => "netscreen",
                        :grok_patterns => ["%{NETSCREENSESSIONLOG}"],
                        :date_key => "date",
                        :date_format => "%b %e %H:%M:%S",
})
$logs.register log

log = Log::TextLog.new({:type => "linux-syslog",
                        :grok_patterns => ["%{SYSLOGPAMSESSION}",
                                           "%{SYSLOGLINE}",
                                          ],
                        :date_key => "date",
                        :date_format => "%b %e %H:%M:%S",
})
$logs.register log
