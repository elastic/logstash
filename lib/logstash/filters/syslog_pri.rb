require "logstash/filters/base"
require "logstash/namespace"

# Filter plugin for logstash to parse the PRI field from the front
# of a Syslog (RFC3164) message.
#
# This filter is based on the original syslog.rb code shipped
# with logstash.
class LogStash::Filters::Syslog_pri < LogStash::Filters::Base
  config_name "syslog_pri"

  # set the status to experimental/beta/stable
  plugin_status "experimental"

  # Add human-readable names after parsing severity and facility from PRI
  config :use_labels, :validate => :boolean, :default => true

  # Name of field which passes in the extracted PRI part of the syslog message
  config :syslog_pri_field_name, :validate => :string, :default => "syslog_pri"

  # Labels for facility levels. This comes from RFC3164.
  config :facility_labels, :validate => :array, :default => [
    "kernel",
    "user-level",
    "mail",
    "daemon",
    "security/authorization",
    "syslogd",
    "line printer",
    "network news",
    "uucp",
    "clock",
    "security/authorization",
    "ftp",
    "ntp",
    "log audit",
    "log alert",
    "clock",
    "local0",
    "local1",
    "local2",
    "local3",
    "local4",
    "local5",
    "local6",
    "local7"
  ]

  # Labels for severity levels. This comes from RFC3164.
  config :severity_labels, :validate => :array, :default => [
    "emergency",
    "alert",
    "critical",
    "error",
    "warning",
    "notice",
    "informational",
    "debug"
  ]

  public
  def register
    # Nothing
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    parse_pri(event)
    filter_matched(event)
  end # def filter

  private
  def parse_pri(event)
    # Per RFC3164, priority = (facility * 8) + severity
    # = (facility << 3) & (severity)
    priority = event.fields[@syslog_pri_field_name].first.to_i rescue 13
    severity = priority & 7 # 7 is 111 (3 bits)
    $stderr.puts "priority=#{priority} severity=#{severity}"
    facility = priority >> 3
    event.fields["syslog_severity_code"] = severity
    event.fields["syslog_facility_code"] = facility

    # Add human-readable names after parsing severity and facility from PRI
    if @use_labels
      facility_number = event.fields["syslog_facility_code"]
      severity_number = event.fields["syslog_severity_code"]

      if @facility_labels[facility_number]
        event.fields["syslog_facility"] = @facility_labels[facility_number]
      end

      if @severity_labels[severity_number]
        event.fields["syslog_severity"] = @severity_labels[severity_number]
      end
    end
  end # def parse_pri
end # class LogStash::Filters::SyslogPRI
