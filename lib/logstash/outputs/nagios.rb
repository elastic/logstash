# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"

# The Nagios output is used for sending passive check results to Nagios via the
# Nagios command file. This output currently supports Nagios 3.
#
# For this output to work, your event _must_ have the following Logstash event fields:
#
#  * `nagios\_host`
#  * `nagios\_service`
#
# These Logstash event fields are supported, but optional:
#
#  * `nagios\_annotation`
#  * `nagios\_level` (overrides `nagios\_level` configuration option)
#
# There are two configuration options:
#
#  * `commandfile` - The location of the Nagios external command file. Defaults
#    to '/var/lib/nagios3/rw/nagios.cmd'
#  * `nagios\_level` - Specifies the level of the check to be sent. Defaults to
#    CRITICAL and can be overriden by setting the "nagios\_level" field to one
#    of "OK", "WARNING", "CRITICAL", or "UNKNOWN"
#
#     output{
#       if [message] =~ /(error|ERROR|CRITICAL)/ {
#         nagios {
#           # your config here
#         }
#       }
#     }
#
class LogStash::Outputs::Nagios < LogStash::Outputs::Base

  config_name "nagios"
  milestone 2

  # The full path to your Nagios command file.
  config :commandfile, :validate => :path, :default => "/var/lib/nagios3/rw/nagios.cmd"

  # The Nagios check level. Should be one of 0=OK, 1=WARNING, 2=CRITICAL,
  # 3=UNKNOWN. Defaults to 2 - CRITICAL.
  config :nagios_level, :validate => [ "0", "1", "2", "3" ], :default => "2"

  public
  def register
    # nothing to do
  end # def register

  public
  def receive(event)
    return unless output?(event)

    if !File.exists?(@commandfile)
      @logger.warn("Skipping nagios output; command file is missing",
                   :commandfile => @commandfile, :missed_event => event)
      return
    end

    # TODO(petef): if nagios_host/nagios_service both have more than one
    # value, send multiple alerts. They will have to match up together by
    # array indexes (host/service combos) and the arrays must be the same
    # length.

    host = event["nagios_host"]
    if !host
      @logger.warn("Skipping nagios output; nagios_host field is missing",
                   :missed_event => event)
      return
    end

    service = event["nagios_service"]
    if !service
      @logger.warn("Skipping nagios output; nagios_service field is missing",
                   "missed_event" => event)
      return
    end

    annotation = event["nagios_annotation"]
    level = @nagios_level

    if event["nagios_level"]
      event_level = [*event["nagios_level"]]
      case event_level[0].downcase
      when "ok"
        level = "0"
      when "warning"
        level = "1"
      when "critical"
        level = "2"
      when "unknown"
        level = "3"
      else
        @logger.warn("Invalid Nagios level. Defaulting to CRITICAL", :data => event_level)
      end
    end

    cmd = "[#{Time.now.to_i}] PROCESS_SERVICE_CHECK_RESULT;#{host};#{service};#{level};"
    if annotation
      cmd += "#{annotation}: "
    end
    # In the multi-line case, escape the newlines for the nagios command file
    cmd += (event["message"] || "<no message>").gsub("\n", "\\n")

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
