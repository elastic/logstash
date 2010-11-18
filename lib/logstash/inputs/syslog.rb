require "logstash/inputs/base"
require "eventmachine-tail"
require "socket" # for Socket.gethostname
require "date"
require "logstash/time" # should really use the filters/date.rb bits


class LogStash::Inputs::Syslog < LogStash::Inputs::Base
  def register
    if !@url.host or !@url.port
      @logger.fatal("No host or port given in #{self.class}: #{@url}")
      # TODO(sissel): Make this an actual exception class
      raise "configuration error"
    end

    @logger.info("Starting tcp listener for #{@url}")
    EventMachine::start_server(@url.host, @url.port, TCPInput, self, @logger)

    @logger.info("Starting udp listener for #{@url}")
    EventMachine::open_datagram_socket(@url.host, @url.port, UDPInput, self,
                                       @logger)

    # This comes from RFC3164, mostly.
    @@syslog_re ||= \
      /<([0-9]{1,3})>([A-z]{3} [0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}) (\S+) (.*)/
      #<priority       timestamp          Mmm dd hh:mm:ss             host  msg
  end # def register

  def receive(host, port, message)
    url = @url.clone
    url.host = host
    url.port = port

    # Do some syslog relay-like behavior.
    # * Add syslog headers if there are none
    event = LogStash::Event.new({
      "@message" => message,
      "@type" => @type,
      "@tags" => @tags.clone,
    })
    syslog_relay(event, url)
    @logger.debug(["Got event", event.class, event.to_hash])
    @callback.call(event)
  end # def receive

  # Following RFC3164 where sane, we'll try to parse a received message
  # as if you were relaying a syslog message to it.
  # If the message cannot be recognized (see @@syslog_re), we'll
  # treat it like the whole event.message is correct and try to fill
  # the missing pieces (host, priority, etc)
  def syslog_relay(event, url)
    match = @@syslog_re.match(event.message)
    if match
      # match[1,2,3,4] = {pri, timestamp, hostname, message}
      # Per RFC3164, priority = (facility * 8) + severity
      #                       = (facility << 3) & (severity)
      priority = match[1].to_i
      severity = priority & 7   # 7 is 111 (3 bits)
      facility = priority >> 3
      event.fields["priority"] = priority
      event.fields["severity"] = severity
      event.fields["facility"] = facility
     
      # TODO(sissel): Use the date filter, somehow.
      event.timestamp = LogStash::Time.to_iso8601(
        DateTime.strptime(match[2], "%b %d %H:%M:%S"))

      # At least the hostname is simple...
      url.host = match[3]
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

  class TCPInput < EventMachine::Connection
    def initialize(receiver, logger)
      @logger = logger
      @receiver = receiver
      @buffer = BufferedTokenizer.new  # From eventmachine
    end # def initialize

    # Messages over TCP may not be received all at once, chunk by newline.
    def receive_data(data)
      @buffer.extract(data).each do |line|
        port, host = Socket.unpack_sockaddr_in(self.get_peername)
        # Trim trailing newlines 
        @receiver.receive(host, port, line.chomp)
      end
    end # def receive_data
  end # class TCPInput

  class UDPInput < EventMachine::Connection
    def initialize(receiver, logger)
      @logger = logger
      @receiver = receiver
    end # def initialize

    # Every udp packet is a unique message.
    def receive_data(data)
      port, host = Socket.unpack_sockaddr_in(self.get_peername)
      # Trim trailing newlines 
      @receiver.receive(host, port, data.chomp)
    end # def receive_data
  end # class UDPInput
end # class LogStash::Inputs::Tcp
