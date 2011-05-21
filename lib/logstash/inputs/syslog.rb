require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/time" # should really use the filters/date.rb bits
require "socket"

# Read syslog messages as events over the network.
#
# This input is a good choice if you already use syslog today.
# It is also a good choice if you want to receive logs from
# appliances and network devices where you cannot run your own
# log collector.
class LogStash::Inputs::Syslog < LogStash::Inputs::Base
  config_name "syslog"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on
  config :port, :validate => :number, :default => 514

  public
  def initialize(params)
    super

    # force "plain" format. others don't make sense here.
    @format = ["plain"]
  end # def initialize

  public
  def register
    # This comes from RFC3164, mostly.
    # Optional fields (priority, host) are because some syslog implementations
    # don't send these under some circumstances.
    @@syslog_re ||= \
      /(?:<([0-9]{1,3})>)?([A-z]{3}  ?[0-9]{1,2} [0-9]{2}:[0-9]{2}:[0-9]{2}) (?:(\S+[^:]) )?(.*)/
      #<priority>      timestamp          Mmm dd hh:mm:ss             host  msg
  end # def register

  public
  def run(output_queue)
    # udp server
    Thread.new do
      LogStash::Util::set_thread_name("input|syslog|udp")
      begin
        udp_listener(output_queue)
      rescue
        @logger.warn("syslog udp listener died: #{$!}")
        sleep(5)
        retry
      end # begin
    end # Thread.new

    # tcp server
    Thread.new do
      LogStash::Util::set_thread_name("input|syslog|tcp")
      begin
        tcp_listener(output_queue)
      rescue
        @logger.warn("syslog tcp listener died: #{$!}")
        sleep(5)
        retry
      end # begin
    end # Thread.new
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting syslog udp listener on #{@host}:#{@port}")
    server = UDPSocket.new(Socket::AF_INET)
    server.bind(@host, @port)

    loop do
      line, client = server.recvfrom(9000)
      source = URI::Generic.new("syslog", nil, client[3], nil, nil, nil, nil,
                                nil, nil, nil)
      e = to_event(line.chomp, source.to_s)
      if e
        syslog_relay(e, source)
        output_queue << e
      end
    end
  ensure
    if server
      server.close_read
      server.close_write
    end
  end # def udp_listener

  private
  def tcp_listener(output_queue)
    @logger.info("Starting syslog tcp listener on #{@host}:#{@port}")
    server = TCPServer.new(@host, @port)

    loop do
      Thread.new(server.accept) do |client|
        ip, port = client.peeraddr[3], client.peeraddr[1]
        @logger.warn("got connection from #{ip}:#{port}")
        LogStash::Util::set_thread_name("input|syslog|tcp|#{ip}:#{port}}")
        source_base = URI::Generic.new("syslog", nil, ip, nil, nil, nil, nil,
                                        nil, nil, nil)
        client.each do |line|
          e = to_event(line.chomp, source_base.to_s)
          if e
            source = source_base.dup
            syslog_relay(e, source)
            output_queue << e
          end # e
        end # client.each
      end # Thread.new
    end # loop do
  ensure
    server.close if server
  end # def tcp_listener

  # Following RFC3164 where sane, we'll try to parse a received message
  # as if you were relaying a syslog message to it.
  # If the message cannot be recognized (see @@syslog_re), we'll
  # treat it like the whole event.message is correct and try to fill
  # the missing pieces (host, priority, etc)
  public
  def syslog_relay(event, url)
    match = @@syslog_re.match(event.message)
    if match
      # match[1,2,3,4] = {pri, timestamp, hostname, message}
      # Per RFC3164, priority = (facility * 8) + severity
      #                       = (facility << 3) & (severity)
      priority = match[1].to_i rescue 13
      severity = priority & 7   # 7 is 111 (3 bits)
      facility = priority >> 3
      event.fields["priority"] = priority
      event.fields["severity"] = severity
      event.fields["facility"] = facility

      # TODO(sissel): Use the date filter, somehow.
      event.timestamp = LogStash::Time.to_iso8601(
        DateTime.strptime(match[2], "%b %d %H:%M:%S"))

      # Hostname is optional, use if present in message, otherwise use source
      # address of message.
      url.host = match[3] if match[3]
      url.port = nil
      event.source = url

      event.message = match[4]
    else
      @logger.info(["NOT SYSLOG", event.message])
      url.host = Socket.gethostname if url.host == "127.0.0.1"

      # RFC3164 says unknown messages get pri=13
      priority = 13
      severity = priority & 7   # 7 is 111 (3 bits)
      facility = priority >> 3
      event.fields["priority"] = 13
      event.fields["severity"] = 5   # 13 & 7 == 5
      event.fields["facility"] = 1   # 13 >> 3 == 1

      # Don't need to modify the message, here.
      # event.message = ...

      event.source = url
    end
  end # def syslog_relay
end # class LogStash::Inputs::Syslog
