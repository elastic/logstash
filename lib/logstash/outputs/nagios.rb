require "logstash/namespace"
require "logstash/outputs/base"

# The nagios output is used for sending passive check results to nagios via the
# nagios command file. 
#
# For this output to work, your event must have the following fields:
#   "nagios_host"
#   "nagios_service"
#
# This field is supported, but optional:
#   "nagios_annotation"
#
# The easiest way to use this output is with the grep filter.
# Presumably, you only want certain events matching a given pattern
# to send events to nagios. So use grep to match and also to add the required
# fields.
#
#     filter {
#       grep {
#         type => "linux-syslog"
#         match => [ "@message", "(error|ERROR|CRITICAL)" ]
#         add_tag => [ "nagios-update" ]
#         add_fields => [
#           "nagios_host", "%{@source_host}",
#           "nagios_service", "the name of your nagios service check"
#         ]
#       }
#     }
#    
#     output{
#       nagios { 
#         # only process events with this tag
#         tags => "nagios-update"
#       }
#     }
class LogStash::Outputs::Nagios < LogStash::Outputs::Base
  NAGIOS_CRITICAL = 2
  NAGIOS_WARN = 1

  config_name "nagios"

  # The path to your nagios command file
  config :commandfile, :validate => :string, :default => "/var/lib/nagios3/rw/nagios.cmd"

  # Only handle events with any of these tags. Optional.
  # If not specified, will process all events.
  config :tags, :validate => :array, :default => []

  public
  def register
    # nothing to do
  end # def register

  public
  def receive(event)
    if !@tags.empty?
      if (event.tags - @tags).size == 0
        # Skip events that have no tags in common with what we were configured
        return
      end
    end

    if !File.exists?(@commandfile)
      @logger.warn("Skipping nagios output; command file is missing",
                   :commandfile => @commandfile, :missed_event => event)
      return
    end

    # TODO(petef): if nagios_host/nagios_service both have more than one
    # value, send multiple alerts. They will have to match up together by
    # array indexes (host/service combos) and the arrays must be the same
    # length.

    host = event.fields["nagios_host"]
    if !host
      @logger.warn("Skipping nagios output; nagios_host field is missing",
                   :missed_event => event)
      return
    end

    service = event.fields["nagios_service"]
    if !service
      @logger.warn("Skipping nagios output; nagios_service field is missing",
                   "missed_event" => event)
      return
    end

    annotation = event.fields["nagios_annotation"]
    level = NAGIOS_CRITICAL
    if event.fields["nagios_level"] and event.fields["nagios_level"][0].downcase == "warn"
      level = NAGIOS_WARN
    end

    cmd = "[#{Time.now.to_i}] PROCESS_SERVICE_CHECK_RESULT;#{host[0]};#{service[0]};#{level};"
    if annotation
      cmd += "#{annotation[0]}: "
    end
    cmd += "#{event.source}: "
    # In the multi-line case, escape the newlines for the nagios command file
    cmd += event.message.gsub("\n", "\\n")

    @logger.debug("Opening nagios command file", :commandfile => @commandfile,
                  :nagios_command => cmd)
    begin
      File.open(@commandfile, "r+") do |f|
        f.puts(cmd)
        f.flush # TODO(sissel): probably don't need this.
      end
    rescue => e
      @logger.warn("Skipping nagios output; error writing to command file",
                   :commandfile => @commandfile, :missed_event => event,
                   :exception => e, :backtrace => e.backtrace)
    end
  end # def receive
end # class LogStash::Outputs::Nagios
