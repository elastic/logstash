require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "timeout"

# Read events over a TCP socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
class LogStash::Inputs::Tcp < LogStash::Inputs::Base

  config_name "tcp"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # the port to listen on
  config :port, :validate => :number, :required => true

  # Read timeout in seconds. If a particular tcp connection is
  # idle for more than this timeout period, we will assume
  # it is dead and close it.
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => 5

  # Enable server.
  config :server, :validate => :boolean, :default => true

  module SocketPeer
    def peer
      "#{peeraddr[3]}:#{peeraddr[1]}"
    end
  end

  public
  def register
    if @server
      @logger.info("Starting tcp listener on #{@host}:#{@port}")
      @server = TCPServer.new(@host, @port)
    else
      @socket = nil
    end
  end # def register

  def handle_socket(socket, output_queue, event_source)
    begin
      loop do
        buf = nil
        # NOTE(petef): the timeout only hits after the line is read
        # or socket dies
        # TODO(sissel): Why do we have a timeout here? What's the point?
        if @data_timeout == -1
          buf = socket.readline
        else
          Timeout::timeout(@data_timeout) do
            buf = socket.readline
          end
        end
        e = self.to_event(buf, event_source)
        if e
          output_queue << e
        end
      end # loop do
    rescue => e
      @logger.debug(["Closing connection with #{socket.peer}", $!])
      @logger.debug(["Backtrace", e.backtrace])
    rescue Timeout::Error
      @logger.debug("Closing connection with #{socket.peer} after read timeout")
    end # begin

    begin
      socket.close
    rescue IOError
      pass
    end # begin
  end

  public
  def run(output_queue)
    if @server
      loop do
        # Start a new thread for each connection.
        Thread.start(@server.accept) do |s|
          # TODO(sissel): put this block in its own method.
          s.instance_eval { class << self; include SocketPeer end }
          @logger.debug("Accepted connection from #{s.peer} on #{@host}:#{@port}")
          handle_socket(s, output_queue, "tcp://#{@host}:#{@port}/client/#{s.peer}")
        end # Thread.start
      end # loop (outer)
    else
      loop do
        socket = TCPSocket.new(@host, @port)
        socket.instance_eval { class << self; include SocketPeer end }
        @logger.debug("Opened connection to #{socket.peer}")
        handle_socket(socket, output_queue, "tcp://#{socket.peer}/server")
      end
    end
  end # def run
end # class LogStash::Inputs::Tcp
