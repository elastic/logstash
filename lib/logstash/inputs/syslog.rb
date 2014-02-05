# encoding: utf-8
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
# RFC3164 style or ISO8601. Otherwise the rest of RFC3164 must be obeyed.
# If you do not use RFC3164, do not use this input.
#
# For more information see (the RFC3164 page)[http://www.ietf.org/rfc/rfc3164.txt].
#
# Note: this input will start listeners on both TCP and UDP.
class LogStash::Inputs::Syslog < LogStash::Inputs::Base
  config_name "syslog"
  milestone 1

  default :codec, "plain"

  # The address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 514

  # Use label parsing for severity and facility levels.
  config :use_labels, :validate => :boolean, :default => true

  # Labels for facility levels. These are defined in RFC3164.
  config :facility_labels, :validate => :array, :default => [ "kernel", "user-level", "mail", "system", "security/authorization", "syslogd", "line printer", "network news", "UUCP", "clock", "security/authorization", "FTP", "NTP", "log audit", "log alert", "clock", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7" ]

  # Labels for severity levels. These are defined in RFC3164.
  config :severity_labels, :validate => :array, :default => [ "Emergency" , "Alert", "Critical", "Error", "Warning", "Notice", "Informational", "Debug" ]

  public
  def initialize(params)
    super
    @shutdown_requested = false
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
    require "thread_safe"
    @grok_filter = LogStash::Filters::Grok.new(
      "overwrite" => "message",
      "match" => { "message" => "<%{POSINT:priority}>%{SYSLOGLINE}" },
    )

    @date_filter = LogStash::Filters::Date.new(
      "match" => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss", "ISO8601"]
    )

    @grok_filter.register
    @date_filter.register

    @tcp_clients = ThreadSafe::Array.new
  end # def register

  public
  def run(output_queue)
    # udp server
    udp_thr = Thread.new do
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
      payload, client = @udp.recvfrom(9000)
      # Ruby uri sucks, so don't use it.
      @codec.decode(payload) do |event|
        decorate(event)
        event["host"] = client[3]
        syslog_relay(event)
        output_queue << event
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
        begin
          client.each do |line|
            @codec.decode(line) do |event|
              decorate(event)
              event["host"] = ip
              syslog_relay(event)
              output_queue << event
            end
          end
        rescue Errno::ECONNRESET
        ensure
          @tcp_clients.delete(client)
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
  # treat it like the whole event["message"] is correct and try to fill
  # the missing pieces (host, priority, etc)
  public
  def syslog_relay(event)
    @grok_filter.filter(event)

    if event["tags"].nil? || !event["tags"].include?("_grokparsefailure")
      # Per RFC3164, priority = (facility * 8) + severity
      #                       = (facility << 3) & (severity)
      priority = event["priority"].to_i rescue 13
      severity = priority & 7   # 7 is 111 (3 bits)
      facility = priority >> 3
      event["priority"] = priority
      event["severity"] = severity
      event["facility"] = facility

      event["timestamp"] = event["timestamp8601"] if event.include?("timestamp8601")
      @date_filter.filter(event)
    else
      @logger.info? && @logger.info("NOT SYSLOG", :message => event["message"])

      # RFC3164 says unknown messages get pri=13
      priority = 13
      event["priority"] = 13
      event["severity"] = 5   # 13 & 7 == 5
      event["facility"] = 1   # 13 >> 3 == 1
    end

    # Apply severity and facility metadata if
    # use_labels => true
    if @use_labels
      facility_number = event["facility"]
      severity_number = event["severity"]

      if @facility_labels[facility_number]
        event["facility_label"] = @facility_labels[facility_number]
      end

      if @severity_labels[severity_number]
        event["severity_label"] = @severity_labels[severity_number]
      end
    end
  end # def syslog_relay
end # class LogStash::Inputs::Syslog
