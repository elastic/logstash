# encoding: utf-8
require "logstash/inputs/base"
require "logstash/errors"
require "logstash/environment"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "socket"
require "timeout"

# Read events over a TCP socket from a Log4j SocketAppender.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`. Depending on which `mode` is configured,
# you need a matching SocketAppender or a SocketHubAppender
# on the remote side.
class LogStash::Inputs::Log4j < LogStash::Inputs::Base

  config_name "log4j"
  milestone 1

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :default => 4560

  # Read timeout in seconds. If a particular TCP connection is
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
    LogStash::Environment.load_elasticsearch_jars!
    require "java"
    require "jruby/serialization"

    begin
      Java::OrgApacheLog4jSpi.const_get("LoggingEvent")
    rescue
      raise(LogStash::PluginLoadingError, "Log4j java library not loaded")
    end

    if server?
      @logger.info("Starting Log4j input listener", :address => "#{@host}:#{@port}")
      @server_socket = TCPServer.new(@host, @port)
    end
    @logger.info("Log4j input")
  end # def register

  private
  def handle_socket(socket, output_queue)
    begin
      # JRubyObjectInputStream uses JRuby class path to find the class to de-serialize to
      ois = JRubyObjectInputStream.new(java.io.BufferedInputStream.new(socket.to_inputstream))
      loop do
        # NOTE: log4j_obj is org.apache.log4j.spi.LoggingEvent
        log4j_obj = ois.readObject
        event = LogStash::Event.new("message" => log4j_obj.getRenderedMessage)
        decorate(event)
        event["host"] = socket.peer
        event["path"] = log4j_obj.getLoggerName
        event["priority"] = log4j_obj.getLevel.toString
        event["logger_name"] = log4j_obj.getLoggerName
        event["thread"] = log4j_obj.getThreadName
        event["class"] = log4j_obj.getLocationInformation.getClassName
        event["file"] = log4j_obj.getLocationInformation.getFileName + ":" + log4j_obj.getLocationInformation.getLineNumber
        event["method"] = log4j_obj.getLocationInformation.getMethodName
        event["NDC"] = log4j_obj.getNDC if log4j_obj.getNDC
        event["stack_trace"] = log4j_obj.getThrowableStrRep.to_a.join("\n") if log4j_obj.getThrowableInformation

        # Add the MDC context properties to '@fields'
        if log4j_obj.getProperties
          log4j_obj.getPropertyKeySet.each do |key|
            event[key] = log4j_obj.getProperty(key)
          end
        end

        output_queue << event
      end # loop do
    rescue => e
      @logger.debug("Closing connection", :client => socket.peer,
                    :exception => e)
    rescue Timeout::Error
      @logger.debug("Closing connection after read timeout",
                    :client => socket.peer)
    end # begin
  ensure
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
          handle_socket(s, output_queue)
        end # Thread.start
      end # loop
    else
      loop do
        client_socket = TCPSocket.new(@host, @port)
        client_socket.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Opened connection", :client => "#{client_socket.peer}")
        handle_socket(client_socket, output_queue)
      end # loop
    end
  end # def run
end # class LogStash::Inputs::Log4j
