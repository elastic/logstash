require 'lib/logs'
require 'lib/log/json'
require 'lib/log/text'

$logs = Logs.new

# === define & register your logs below here
access_log = TextLog.new(:name => "access.log",
                         :grok_pattern => "%{COMBINEDAPACHELOG}",
                         :date_key => "timestamp",
                         :date_format => "%d/%b/%Y:%H:%M:%S %z")
$logs.register access_log

apache = TextLog.new({ :name => "httpd-access",
                       #:grok_pattern => "%{SYSLOGBASE} Accepted %{NOTSPACE:method} for %{DATA:user} from %{IPORHOST:client} port %{INT:port}",
                       :grok_pattern => "%{COMBINEDAPACHELOG}",
                       :date_key => "timestamp",
                       :date_format => "%d/%b/%Y:%H:%M:%S %Z",
});

$logs.register apache

glu_log_config = {:name => "glu",
                  :date_key => "timestamp",
                  :date_format => "%Y-%m-%dT%H:%M:%S",
                  :line_format => "<%= entry['timestamp'] %> | <%= entry['level'] %> | <%= entry['context/sessionKey'] %> | <%= entry['sourceHostName'] %> | <%= entry['context/componentName'] %> | <%= entry['message'] %>",
                 }
glu_log = JsonLog.new(glu_log_config)
$logs.register glu_log

netscreen_log = TextLog.new(:name => "netscreenlog",
                            :grok_pattern => "%{NETSCREENSESSIONLOG}",
                            :date_key => "date",
                            :date_format => "%b %e %H:%M:%S")
$logs.register netscreen_log
