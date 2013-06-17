require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "socket"
require "timeout"

# Read events over a TCP socket from Log4j SocketAppender.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`. Depending on mode, you need a matching SocketAppender or SocketHubAppender on the remote side
class LogStash::Inputs::Log4j < LogStash::Inputs::Base

  config_name "log4j"
  milestone 1

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

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    require "java"
    require "jruby/serialization"

    if server?
      @logger.info("Starting Log4j input listener", :address => "#{@host}:#{@port}")
      @server_socket = TCPServer.new(@host, @port)
    end
    @logger.info("Log4j input")
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      # JRubyObjectInputStream uses JRuby class path to find the class to de-serialize to
      ois = JRubyObjectInputStream.new(java.io.BufferedInputStream.new(socket.to_inputstream))
      loop do
        # NOTE: event_raw is org.apache.log4j.spi.LoggingEvent
        event_obj = ois.readObject()
        e = to_event(event_obj.getRenderedMessage(), event_source)
        e.source_host = socket.peer
        e.source_path = event_obj.getLoggerName()
        e["priority"] = event_obj.getLevel().toString()
        e["logger_name"] = event_obj.getLoggerName()
        e["thread"] = event_obj.getThreadName()
        e["class"] = event_obj.getLocationInformation().getClassName()
        e["file"] = event_obj.getLocationInformation().getFileName() + ":" + event_obj.getLocationInformation().getLineNumber(),
        e["method"] = event_obj.getLocationInformation().getMethodName()
        e["NDC"] = event_obj.getNDC() if event_obj.getNDC()
        e["stack_trace"] = event_obj.getThrowableStrRep().to_a.join("\n") if event_obj.getThrowableInformation()
        
        # Add the MDC context properties to '@fields'
        if event_obj.getProperties()
          event_obj.getPropertyKeySet().each do |key|
            e[key] = event_obj.getProperty(key)
          end  
        end  

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
          s.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
          @logger.debug("Accepted connection", :client => s.peer,
                        :server => "#{@host}:#{@port}")
          handle_socket(s, output_queue, "tcp://#{@host}:#{@port}/client/#{s.peer}")
        end # Thread.start
      end # loop
    else
      loop do
        client_socket = TCPSocket.new(@host, @port)
        client_socket.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Opened connection", :client => "#{client_socket.peer}")
        handle_socket(client_socket, output_queue, "tcp://#{client_socket.peer}/server")
      end # loop
    end
  end # def run
end # class LogStash::Inputs::Log4j
