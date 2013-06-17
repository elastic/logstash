require "date"
require "logstash/filters/grok"
require "logstash/filters/date"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read syslog messages as events over the network.
#
# This input is a good choice if you already use syslog today.
# It is also a good choice if you want to receive logs from
# appliances and network devices where you cannot run your own
# log collector.
#
# Of course, 'syslog' is a very muddy term. This input only supports RFC3164
# syslog with some small modifications. The date format is allowed to be
# RFC3164 style or ISO8601. Otherwise the rest of the RFC3164 must be obeyed.
# If you do not use RFC3164, do not use this input.
#
# Note: this input will start listeners on both TCP and UDP
class LogStash::Inputs::Syslog < LogStash::Inputs::Base
  config_name "syslog"
  milestone 1

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 514

  # Use label parsing for severity and facility levels
  config :use_labels, :validate => :boolean, :default => true

  # Labels for facility levels
  # This comes from RFC3164.
  config :facility_labels, :validate => :array, :default => [ "kernel", "user-level", "mail", "system", "security/authorization", "syslogd", "line printer", "network news", "UUCP", "clock", "security/authorization", "FTP", "NTP", "log audit", "log alert", "clock", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7" ]

  # Labels for severity levels
  # This comes from RFC3164.
  config :severity_labels, :validate => :array, :default => [ "Emergency" , "Alert", "Critical", "Error", "Warning", "Notice", "Informational", "Debug" ]

  public
  def initialize(params)
    super
    @shutdown_requested = false
    BasicSocket.do_not_reverse_lookup = true

    # force "plain" format. others don't make sense here.
    @format = "plain"
  end # def initialize

  public
  def register
    @logger.warn("ATTENTION: THIS PLUGIN WILL BE REMOVED IN LOGSTASH 1.2.0. YOU MAY CONTINUE USING IT. WHEN REMOVED, TO LEARN HOW TO REPLACE THIS PLUGIN, SEE THIS URL: http://cookbook.logstash.net/recipes/syslog-pri/")
    @grok_filter = LogStash::Filters::Grok.new({
      "type"    => [@config["type"]],
      "pattern" => ["<%{POSINT:priority}>%{SYSLOGLINE}"],
    })

    @date_filter = LogStash::Filters::Date.new({
      "type"          => [@config["type"]],
      "timestamp"     => ["MMM  d HH:mm:ss", "MMM dd HH:mm:ss"],
      "timestamp8601" => ["ISO8601"],
    })

    @grok_filter.register
    @date_filter.register

    @tcp_clients = []
  end # def register

  public
  def run(output_queue)
    # udp server
    udp_thr = Thread.new do
      LogStash::Util::set_thread_name("input|syslog|udp")
      begin
        udp_listener(output_queue)
      rescue => e
        break if @shutdown_requested
        @logger.warn("syslog udp listener died",
                     :address => "#{@host}:#{@port}", :exception => e,
                     :backtrace => e.backtrace)
        sleep(5)
        retry
      end # begin
    end # Thread.new

    # tcp server
    tcp_thr = Thread.new do
      LogStash::Util::set_thread_name("input|syslog|tcp")
      begin
        tcp_listener(output_queue)
      rescue => e
        break if @shutdown_requested
        @logger.warn("syslog tcp listener died",
                     :address => "#{@host}:#{@port}", :exception => e,
                     :backtrace => e.backtrace)
        sleep(5)
        retry
      end # begin
    end # Thread.new

    # If we exit and we're the only input, the agent will think no inputs
    # are running and initiate a shutdown.
    udp_thr.join
    tcp_thr.join
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting syslog udp listener", :address => "#{@host}:#{@port}")

    if @udp
      @udp.close
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

    loop do
      line, client = @udp.recvfrom(9000)
      # Ruby uri sucks, so don't use it.
      source = "syslog://#{client[3]}/"
      e = to_event(line.chomp, source)
      if e
        syslog_relay(e, source)
        output_queue << e
      end
    end
  ensure
    close_udp
  end # def udp_listener

  private
  def tcp_listener(output_queue)
    @logger.info("Starting syslog tcp listener", :address => "#{@host}:#{@port}")
    @tcp = TCPServer.new(@host, @port)
    @tcp_clients = []

    loop do
      client = @tcp.accept
      @tcp_clients << client
      Thread.new(client) do |client|
        ip, port = client.peeraddr[3], client.peeraddr[1]
        @logger.info("new connection", :client => "#{ip}:#{port}")
        LogStash::Util::set_thread_name("input|syslog|tcp|#{ip}:#{port}}")
        if ip.include?(":") # ipv6
          source = "syslog://[#{ip}]/"
        else
          source = "syslog://#{ip}/"
        end

        begin
        client.each do |line|
          e = to_event(line.chomp, source)
          if e
            syslog_relay(e, source)
            output_queue << e
          end # e
        end # client.each
        rescue Errno::ECONNRESET
        end
      end # Thread.new
    end # loop do
  ensure
    close_tcp
  end # def tcp_listener

  public
  def teardown
    @shutdown_requested = true
    close_udp
    close_tcp
    finished
  end

  private
  def close_udp
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
    @udp = nil
  end

  private
  def close_tcp
    # If we somehow have this left open, close it.
    @tcp_clients.each do |client|
      client.close rescue nil
    end
    @tcp.close if @tcp rescue nil
    @tcp = nil
  end

  # Following RFC3164 where sane, we'll try to parse a received message
  # as if you were relaying a syslog message to it.
  # If the message cannot be recognized (see @grok_filter), we'll
  # treat it like the whole event.message is correct and try to fill
  # the missing pieces (host, priority, etc)
  public
  def syslog_relay(event, url)
    @grok_filter.filter(event)

    if !event.tags.include?("_grokparsefailure")
      # Per RFC3164, priority = (facility * 8) + severity
      #                       = (facility << 3) & (severity)
      priority = event.fields["priority"].first.to_i rescue 13
      severity = priority & 7   # 7 is 111 (3 bits)
      facility = priority >> 3
      event.fields["priority"] = priority
      event.fields["severity"] = severity
      event.fields["facility"] = facility

      @date_filter.filter(event)
    else
      @logger.info("NOT SYSLOG", :message => event.message)
      url = "syslog://#{Socket.gethostname}/" if url == "syslog://127.0.0.1/"

      # RFC3164 says unknown messages get pri=13
      priority = 13
      event.fields["priority"] = 13
      event.fields["severity"] = 5   # 13 & 7 == 5
      event.fields["facility"] = 1   # 13 >> 3 == 1

      # Don't need to modify the message, here.
      # event.message = ...

      event.source = url
    end

    # Apply severity and facility metadata if
    # use_labels => true
    if @use_labels
      facility_number = event.fields["facility"]
      severity_number = event.fields["severity"]

      if @facility_labels[facility_number]
        event.fields["facility_label"] = @facility_labels[facility_number]
      end

      if @severity_labels[severity_number]
        event.fields["severity_label"] = @severity_labels[severity_number]
      end
    end
  end # def syslog_relay
end # class LogStash::Inputs::Syslog
