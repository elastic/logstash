require "logstash/filters/base"
require "logstash/namespace"

# The GELFify filter parses RFC3164 severity levels to
# corresponding GELF levels.
class LogStash::Filters::Gelfify < LogStash::Filters::Base

  config_name "gelfify"

  public
  def register

    @syslog_level_map  = {
        0 => 3, # Emergency => FATAL
        1 => 5, # Alert     => WARN
        2 => 3, # Critical  => FATAL
        3 => 4, # Error     => ERROR
        4 => 5, # Warning   => WARN
        5 => 6, # Notice    => INFO
        6 => 6, # Informat. => INFO
        7 => 7  # Debug     => DEBUG
    }
    
    @logger.debug "Adding GELFify filter to type #{@type}"

  end # def register

  public
  def filter(event)

    return unless event.type == @type
    @logger.debug "GELFIFY FILTER: received event of type #{event.type}"

    if event.fields.include?("severity")

        if @syslog_level_map[event.fields["severity"].to_i]
            @logger.debug "GELFIFY FILTER: Severity level successfully mapped"
            event.fields["GELF_severity"] = @syslog_level_map[event.fields["severity"].to_i]
        end

    else
        @logger.warn "GELFIFY FILTER: No 'severity' field found"
    end

    if !event.cancelled?
      filter_matched(event)
    end
  end # def filter

end # class LogStash::Filters::Gelfify
