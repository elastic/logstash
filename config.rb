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

glu_log_config = {:name => "glu",
                  :date_key => "timestamp",
                  :date_format => "%Y-%m-%dT%H:%M:%S",
                  :line_format => "<%= entry['timestamp'] %> | <%= entry['level'] %> | <%= entry['context/sessionKey'] %> | <%= entry['sourceHostName'] %> | <%= entry['context/componentName'] %> | <%= entry['message'] %>",
                 }
glu_log = JsonLog.new(glu_log_config)
$logs.register glu_log

netscreen_log = TextLog.new(:name => "netscreenlog",
                            :grok_pattern => "%{SYSLOGDATE:date} %{IPORHOST:device} %{IPORHOST}: NetScreen device_id=%{WORD:device_id}%{DATA}: start_time=%{QUOTEDSTRING:start_time} duration=%{INT:duration} policy_id=%{INT:policy_id} service=%{DATA:service} proto=%{INT:proto} src zone=%{WORD:src_zone} dst zone=%{WORD:dst_zone} action=%{WORD:action} sent=%{INT:sent} rcvd=%{INT:rcvd} src=%{IPORHOST:src_ip} dst=%{IPORHOST:dst_ip} src_port=%{INT:src_port} dst_port=%{INT:dst_port} src-xlated ip=%{IPORHOST:src_xlated_ip} port=%{INT:src_xlated_port} dst-xlated ip=%{IPORHOST:dst_xlated_ip} port=%{INT:dst_xlated_port} session_id=%{INT:session_id} reason=%{GREEDYDATA:reason}",
                            :date_key => "date",
                            :date_format => "%b %e %H:%M:%S")
$logs.register netscreen_log
