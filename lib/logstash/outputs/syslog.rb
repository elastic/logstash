require "logstash/outputs/base"
require "logstash/namespace"
require "date"

# Send events to a syslog server.
#
# You can send messages compliant with RFC3164 or RFC5424
# UDP or TCP syslog transport is supported
class LogStash::Outputs::Syslog < LogStash::Outputs::Base
  config_name "syslog"
  milestone 1

  FACILITY_LABELS = [
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
    "local7",
  ]

  SEVERITY_LABELS = [
    "emergency",
    "alert",
    "critical",
    "error",
    "warning",
    "notice",
    "informational",
    "debug",
  ]

  # syslog server address to connect to
  config :host, :validate => :string, :required => true
  
  # syslog server port to connect to
  config :port, :validate => :number, :required => true

  # syslog server protocol. you can choose between udp and tcp
  config :protocol, :validate => ["tcp", "udp"], :default => "udp"

  # facility label for syslog message
  config :facility, :validate => FACILITY_LABELS, :required => true

  # severity label for syslog message
  config :severity, :validate => SEVERITY_LABELS, :required => true

  # source host for syslog message
  config :sourcehost, :validate => :string, :default => "%{host}"

  # timestamp for syslog message
  config :timestamp, :validate => :string, :default => "%{@timestamp}", :deprecated => "This setting is no longer necessary. The RFC setting will determine what time format is used."

  # application name for syslog message
  config :appname, :validate => :string, :default => "LOGSTASH"

  # process id for syslog message
  config :procid, :validate => :string, :default => "-"
 
  # message id for syslog message
  config :msgid, :validate => :string, :default => "-"

  # syslog message format: you can choose between rfc3164 or rfc5424
  config :rfc, :validate => ["rfc3164", "rfc5424"], :default => "rfc3164"

  
  public
  def register
      @client_socket = nil
  end

  private
  def udp?
    @protocol == "udp"
  end

  private
  def rfc3164?
    @rfc == "rfc3164"
  end 

  private
  def connect
    if udp?
        @client_socket = UDPSocket.new
        @client_socket.connect(@host, @port)
    else
        @client_socket = TCPSocket.new(@host, @port)
    end
  end

  public
  def receive(event)
    return unless output?(event)

    appname = event.sprintf(@appname)
    procid = event.sprintf(@procid)
    sourcehost = event.sprintf(@sourcehost)

    facility_code = FACILITY_LABELS.index(@facility)

    severity_code = SEVERITY_LABELS.index(@severity)

    priority = (facility_code * 8) + severity_code

    if rfc3164?
      timestamp = event.sprintf("%{+MMM dd HH:mm:ss}")
      syslog_msg = "<"+priority.to_s()+">"+timestamp+" "+sourcehost+" "+appname+"["+procid+"]: "+event["message"]
    else
      msgid = event.sprintf(@msgid)
      timestamp = event.sprintf("%{+YYYY-MM-dd'T'HH:mm:ss.SSSZ}")
      syslog_msg = "<"+priority.to_s()+">1 "+timestamp+" "+sourcehost+" "+appname+" "+procid+" "+msgid+" - "+event["message"]
    end

    begin
      connect unless @client_socket
      @client_socket.write(syslog_msg + "\n")
    rescue => e
      @logger.warn(@protocol+" output exception", :host => @host, :port => @port,
                 :exception => e, :backtrace => e.backtrace)
      @client_socket.close rescue nil
      @client_socket = nil
    end
  end
end

