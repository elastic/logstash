require "logstash/filters/base"
require "logstash/namespace"

# The GELFify filter parses RFC3164 severity levels to
# corresponding GELF levels.
class LogStash::Filters::Gelfify < LogStash::Filters::Base
  config_name "gelfify"
  plugin_status "unstable"

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

  public
  def register
    # nothing
  end # def register

  public
  def filter(event)
    return unless event.type == @type
    @logger.debug("GELFIFY FILTER: received event of type #{event.type}")

    if event.fields.include?("severity")
      sev = event.fields["severity"].to_i rescue nil
      if sev.to_s != event.fields["severity"].to_s
        # severity isn't convertable to an integer.
        # "foo".to_i => 0, which would default to EMERG.
        @logger.debug("GELFIFY FILTER: existing severity field is not an int")
      elsif SYSLOG_LEVEL_MAP[sev]
        @logger.debug("GELFIFY FILTER: Severity level successfully mapped")
        event.fields["GELF_severity"] = SYSLOG_LEVEL_MAP[sev]
      else
        @logger.debug("GELFIFY FILTER: unknown severity #{sev}")
      end
    else
      @logger.debug("GELFIFY FILTER: No 'severity' field found")
    end

    if !event.cancelled?
      filter_matched(event)
    end
  end # def filter
end # class LogStash::Filters::Gelfify
