require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "timeout"

# Read events over a TCP socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Tcp < LogStash::Inputs::Base

  config_name "tcp"
  plugin_status "beta"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # Read timeout in seconds. If a particular tcp connection is
  # idle for more than this timeout period, we will assume
  # it is dead and close it.
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => 5

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  module SocketPeer
    public
    def peer
      "#{peeraddr[3]}:#{peeraddr[1]}"
    end # def peer
  end # module SocketPeer

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    if server?
      @logger.info("Starting tcp input listener", :address => "#{@host}:#{@port}")
      @server_socket = TCPServer.new(@host, @port)
    end
    @event_meter = @logger.metrics.meter(self, "events")
    @logger.info("tcp input", :meter => @event_meter)
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      loop do
        buf = nil
        # NOTE(petef): the timeout only hits after the line is read
        # or socket dies
        # TODO(sissel): Why do we have a timeout here? What's the point?
        if @data_timeout == -1
          buf = readline(socket)
        else
          Timeout::timeout(@data_timeout) do
            buf = readline(socket)
          end
        end
        e = self.to_event(buf, event_source)
        if e
          output_queue << e
        end
      end # loop do
    rescue => e
      @logger.debug("Closing connection", :client => socket.peer,
                    :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Closing connection after read timeout",
                    :client => socket.peer)
    end # begin

    begin
      socket.close
    rescue IOError
      pass
    end # begin
  end

  private
  def server?
    @mode == "server"
  end # def server?

  private
  def readline(socket)
    @event_meter.mark
    line = socket.readline
  end # def readline

  public
  def run(output_queue)
    if server?
      loop do
        # Start a new thread for each connection.
        Thread.start(@server_socket.accept) do |s|
          # TODO(sissel): put this block in its own method.

          # monkeypatch a 'peer' method onto the socket.
          s.instance_eval { class << self; include SocketPeer end }
          @logger.debug("Accepted connection", :client => s.peer,
                        :server => "#{@host}:#{@port}")
          handle_socket(s, output_queue, "tcp://#{@host}:#{@port}/client/#{s.peer}")
        end # Thread.start
      end # loop
    else
      loop do
        client_socket = TCPSocket.new(@host, @port)
        client_socket.instance_eval { class << self; include SocketPeer end }
        @logger.debug("Opened connection", :client => "#{client_socket.peer}")
        handle_socket(client_socket, output_queue, "tcp://#{client_socket.peer}/server")
      end # loop
    end
  end # def run
end # class LogStash::Inputs::Tcp
