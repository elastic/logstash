require "logstash/namespace"
require "logstash/outputs/base"

class LogStash::Outputs::Nagios < LogStash::Outputs::Base
  NAGIOS_CRITICAL = 2
  NAGIOS_WARN = 1

  config_name "nagios"
  config :commandfile, :validate => :string

  public
  def initialize(url, config={}, &block)
    super

    if @url.path == "" or @url.path == "/"
      @cmdfile = "/var/lib/nagios3/rw/nagios.cmd"
    else
      @cmdfile = @url.path
    end
  end # def initialize

  public
  def register
    # nothing to do
  end # def register

  public
  def receive(event)
    if !File.exists?(@cmdfile)
      @logger.warn(["Skipping nagios output; command file is missing",
                   {"cmdfile" => @cmdfile, "missed_event" => event}])
      return
    end

    # TODO(petef): if nagios_host/nagios_service both have more than one
    # value, send multiple alerts. They will have to match up together by
    # array indexes (host/service combos) and the arrays must be the same
    # length.

    host = event.fields["nagios_host"]
    if !host
      @logger.warn(["Skipping nagios output; nagios_host field is missing",
                   {"missed_event" => event}])
      return
    end

    service = event.fields["nagios_service"]
    if !service
      @logger.warn(["Skipping nagios output; nagios_service field is missing",
                   {"missed_event" => event}])
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

    @logger.debug({"cmdfile" => @cmdfile, "nagios_command" => cmd})
    begin
      File.open(@cmdfile, "a") do |f|
        f.puts cmd
      end
    rescue
      @logger.warn(["Skipping nagios output; error writing to command file",
                   {"error" => $!, "cmdfile" => @cmdfile,
                    "missed_event" => event}])
    end
  end # def receive
end # class LogStash::Outputs::Nagios
