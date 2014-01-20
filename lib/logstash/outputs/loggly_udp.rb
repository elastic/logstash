# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'date'

# Got a loggly account? Use logstash to ship logs to Loggly!
#
# udp Support: 
# - parse syslogs and ship structured RFC5424 formatted syslogs over udp.
# - any input type can be used. Default '-' values and current DateTime will
#   be used when not provided. Also supports Loggly search and grouping "Tags"
class LogStash::Outputs::LogglyUdp < LogStash::Outputs::Base
  config_name 'loggly_udp'
  milestone 1

  # Syslog Facility
  FACILITY_LABELS = [
    'kernel',
    'user-level',
    'mail',
    'daemon',
    'security/authorization',
    'syslogd',
    'line printer',
    'network news',
    'uucp',
    'clock',
    'security/authorization',
    'ftp',
    'ntp',
    'log audit',
    'log alert',
    'clock',
    'local0',
    'local1',
    'local2',
    'local3',
    'local4',
    'local5',
    'local6',
    'local7'
  ]

  # Syslog Severity
  SEVERITY_LABELS = [
    'emergency',
    'alert',
    'critical',
    'error',
    'warning',
    'notice',
    'informational',
    'debug'
  ]
  

  # The hostname to send logs to. This should target the loggly udp input
  # server which is usually "logs.loggly.com", "logs-01.loggly.com", or ip 54.236.79.251'
  # Using domain name requires more testing. IP Address works consistently.
  # Seems that sending via udp requires IP address. Needs testing
  config :host, :validate => :string, :default => '54.236.79.251'
  
  # Loggly udp port to connect to
  config :port, :validate => :number, :default => 514

  # Should the log action be sent over https instead of plain http, or udp
  config :protocol, :validate => ['udp'], :default => 'udp'

  # The loggly udp input key \ customer token and udp id to send to.
  # Usually visible on the Source Setup page under Linux logging source. 
  # The same key is used for both http and udp however for udp an id (i.e. "@41058")
  # is appended to the key resulting in "abcdef12-3456-7890-abcd-ef0123456789@41058" 
  #                                      \---------->   key   <-------------/\-id-/
  config :key, :validate => :string, :required => true

  # udp id, the "@" is not included as part of the id
  config :udp_id, :validate => :string, :default => '41058'
    
  # Facility label for syslog message
  config :facility, :validate => FACILITY_LABELS, :required => true

  # Severity label for syslog message
  config :severity, :validate => SEVERITY_LABELS, :required => true
    
  # Source host for syslog message
  config :sourcehost, :validate => :string, :default => "%{host}"
  
  # Application name for syslog message
  config :appname, :validate => :string, :default => 'LOGSTASH'

  # Process id for syslog message
  config :procid, :validate => :string, :default => '-'
 
  # Pessage id for syslog message
  config :msgid, :validate => :string, :default => '-'
  
  # Search Tages within structured data, unable to use 'tags' as variable
  # name conflict in base class.
  config :loggly_tags, :validate => :array, :default => []

  private
  def udp?
    @protocol == 'udp'
  end
  
  public
  def register
    if udp?
      @client_socket = nil
    end
  end
  
  private
  def get_tags
    tags_as_string = ''
    begin
      unless @loggly_tags.empty?
        temp_tags ||= []
        @loggly_tags.each do |t|
          temp_tags << %Q[tag="#{t}"]  
        end      
        tags_as_string = temp_tags.join(' ')
      end
      
      tags_as_string
    rescue => e
      @logger.warn("#{@protocol} output exception", :host => @host, :port => @port, :exception => e, :backtrace => e.backtrace)
    end
  end

  private
  def connect
    @client_socket = UDPSocket.new
    @client_socket.connect(@host, @port)
  end
  
  # returns customer token with udp suffix
  private 
  def get_udp_token
    "#{@key}@#{@udp_id}"
  end

  public
  def receive(event)
    return unless output?(event)

    begin
      appname       = event.sprintf(@appname)
      procid        = event.sprintf(@procid)
      sourcehost    = event.sprintf(@sourcehost)
      facility_code = FACILITY_LABELS.index(@facility)
      severity_code = SEVERITY_LABELS.index(@severity)
      priority      = (facility_code * 8) + severity_code
      msgid         = event.sprintf(@msgid)
      timestamp     = event.sprintf("%{+YYYY-MM-dd'T'HH:mm:ss.SSSZ}")
      token_tags    = @loggly_tags.empty? ? "#{get_udp_token}" : "#{get_udp_token} #{get_tags}"
      syslog_msg    = "<#{priority.to_s}>1 #{timestamp} #{sourcehost} #{appname} #{procid} #{msgid} [#{token_tags}] - #{event["message"]}"
      connect unless @client_socket
      @client_socket.write(syslog_msg + "\n")
      
      @logger.info(syslog_msg)
      
    rescue => e
      @logger.warn("#{@protocol} output exception", :host => @host, :port => @port, :exception => e, :backtrace => e.backtrace)
      @client_socket.close rescue nil
      @client_socket = nil
    end
   
  end # def receive  
end # class LogStash::Outputs::Loggly
