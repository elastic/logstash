# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "uri"
# TODO(sissel): Move to something that performs better than net/http
require "net/http"
require "net/https"
require 'date'

# Ugly monkey patch to get around <http://jira.codehaus.org/browse/JRUBY-5529>
Net::BufferedIO.class_eval do
    BUFSIZE = 1024 * 16

    def rbuf_fill
      timeout(@read_timeout) {
        @rbuf << @io.sysread(BUFSIZE)
      }
    end
end

# Got a loggly account? Use logstash to ship logs to Loggly!
#
# This is most useful so you can use logstash to parse and structure
# your logs and ship structured, json events to your account at Loggly.
#
# To use this, you'll need to use a Loggly input with type 'http'
# and 'json logging' enabled.
class LogStash::Outputs::Loggly < LogStash::Outputs::Base
  config_name "loggly"
  milestone 2
  
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
  

  # The hostname to send logs to. This should target the loggly http input
  # server which is usually "logs.loggly.com", "logs-01.loggly.com", or ip 54.236.79.251'
  # IP Address works consistently over udp, domain name needs more testing.
  config :host, :validate => :string, :default => "logs.loggly.com"

  # Loggly udp port to connect to
  config :port, :validate => :number, :default => 514

  # The loggly http input key to send to.
  # This is usually visible in the Loggly 'Setup' page as something like this
  #   https://logs.hoover.loggly.net/inputs/abcdef12-3456-7890-abcd-ef0123456789
  #                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  #                                         \---------->   key   <-------------/
  # A udp example is also shown under the rsyslog section on the same page.
  #   $template LogglyFormat,"<%pri%>%protocol-version% %timestamp:::date-rfc3339% %HOSTNAME% 
  #   %app-name% %procid% %msgid% [abcdef12-3456-7890-abcd-ef0123456789@41058] %msg%\n"  
  #                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^|^^^^^
  #                                \---------->   key   <-------------/|\id/
  #
  # You can use %{foo} field lookups here if you need to pull the api key from
  # the event. This is mainly aimed at multitenant hosting providers who want
  # to offer shipping a customer's logs to that customer's loggly account.
  config :key, :validate => :string, :required => true

  # udp id, the "@" is not included as part of the id, the id is automatically
  # to key when udp protocol is selected
  config :udp_id, :validate => :string, :default => '41058'
  
  # Facility label for syslog message
  config :facility, :validate => FACILITY_LABELS, :default => 'log alert'

  # Severity label for syslog message
  config :severity, :validate => SEVERITY_LABELS, :default => "informational"
  
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
  
  # Should the log action be sent over https instead of plain http, or udp
  config :proto, :validate => ['http', 'udp'], :default => 'http'

  # Proxy Host
  config :proxy_host, :validate => :string

  # Proxy Port
  config :proxy_port, :validate => :number

  # Proxy Username
  config :proxy_user, :validate => :string

  # Proxy Password
  config :proxy_password, :validate => :password, :default => ""

  private
  def udp?
    @proto == 'udp'
  end
  
  public
  def register
    # if http, nothing to do
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
        if udp?
          @loggly_tags.each do |t|
            temp_tags << %Q[tag="#{t}"]  
          end      
          tags_as_string = temp_tags.join(' ')
        else
          tags_as_string = @loggly_tags.join(',')
        end
      end
      
      tags_as_string
    rescue => e
      @logger.warn("#{@proto} output exception", :host => @host, :port => @port, :exception => e, :backtrace => e.backtrace)
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

    if event == LogStash::SHUTDOWN
      finished
      return
    end

    if udp?
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
        @logger.warn("#{@proto} output exception", :host => @host, :port => @port, :exception => e, :backtrace => e.backtrace)
        @client_socket.close rescue nil
        @client_socket = nil
      end
    else
      # Send the event over http.
      url = URI.parse("#{@proto}://#{@host}/inputs/#{event.sprintf(@key)}")
      
      @logger.info("Loggly URL", :url => url)
      http = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_password.value).new(url.host, url.port)
      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::Post.new(url.path)
      request.body = event.to_json
      
      unless @loggly_tags.empty?
        request.add_field("X-LOGGLY-TAG", "#{@loggly_tags.join(',')}")
      end
      
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        @logger.info("Event send to Loggly OK!")
      else
        @logger.warn("HTTP error", :error => response.error!)
      end
    end
    
  end # def receive
end # class LogStash::Outputs::Loggly
