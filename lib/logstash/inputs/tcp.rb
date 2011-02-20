require "eventmachine-tail"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::Tcp < LogStash::Inputs::Base

  config_name "tcp"

  public
  def initialize(params)
    super
    raise "issue/17: needs refactor to support configfile"
  end # def initialize

  public
  def register
    if !@url.host or !@url.port
      @logger.fatal("No host or port given in #{self.class}: #{@url}")
      # TODO(sissel): Make this an actual exception class
      raise "configuration error"
    end

    @logger.info("Starting tcp listener for #{@url}")
    EventMachine::start_server(@url.host, @url.port, TCPInput, @url, self, @logger)
  end # def register

  public
  def receive(host, port, event)
    url = @url.clone
    url.host = host
    url.port = port
    @logger.debug(["original url", { :originalurl => @url, :newurl => url }])
    event = LogStash::Event.new({
      "@message" => event,
      "@type" => @type,
      "@tags" => @tags.clone,
    })
    event.source = url
    @logger.debug(["Got event", event])
    @callback.call(event)
  end # def receive

  private
  class TCPInput < EventMachine::Connection
    def initialize(url, receiver, logger)
      @logger = logger
      @receiver = receiver
      @url = url;
      @buffer = BufferedTokenizer.new  # From eventmachine
    end # def initialize

    def receive_data(data)
      @buffer.extract(data).each do |line|
        port, host = Socket.unpack_sockaddr_in(self.get_peername)
        @receiver.receive(host, port, line)
      end
    end # def receive_data
  end # class TCPInput
end # class LogStash::Inputs::Tcp
