# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read events over a UNIX socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Unix < LogStash::Inputs::Base
  class Interrupted < StandardError; end
  config_name "unix"
  milestone 2

  default :codec, "line"

  # When mode is `server`, the path to listen on.
  # When mode is `client`, the path to connect to.
  config :path, :validate => :string, :required => true

  # Remove socket file in case of EADDRINUSE failure
  config :force_unlink, :validate => :boolean, :default => false

  # The 'read' timeout in seconds. If a particular connection is idle for
  # more than this timeout period, we will assume it is dead and close it.
  #
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => -1

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    require "socket"
    require "timeout"

    if server?
      @logger.info("Starting unix input listener", :address => "#{@path}", :force_unlink => "#{@force_unlink}")
      begin
        @server_socket = UNIXServer.new(@path)
      rescue Errno::EADDRINUSE, IOError
        if @force_unlink
          File.unlink(@path)
          begin
            @server_socket = UNIXServer.new(@path)
            return
          rescue Errno::EADDRINUSE, IOError
            @logger.error("!!!Could not start UNIX server: Address in use",
                          :path => @path)
            raise
          end
        end
        @logger.error("Could not start UNIX server: Address in use",
                      :path => @path)
        raise
      end
    end
  end # def register

  private
  def handle_socket(socket, output_queue)
    begin
      hostname = Socket.gethostname
      loop do
        buf = nil
        # NOTE(petef): the timeout only hits after the line is read
        # or socket dies
        # TODO(sissel): Why do we have a timeout here? What's the point?
        if @data_timeout == -1
          buf = socket.readpartial(16384)
        else
          Timeout::timeout(@data_timeout) do
            buf = socket.readpartial(16384)
          end
        end
        @codec.decode(buf) do |event|
          decorate(event)
          event["host"] = hostname
          event["path"] = @path
          output_queue << event
        end
      end # loop do
    rescue => e
      @logger.debug("Closing connection", :path => @path,
      :exception => e, :backtrace => e.backtrace)
    rescue Timeout::Error
      @logger.debug("Closing connection after read timeout",
      :path => @path)
    end # begin

  ensure
    begin
      socket.close
    rescue IOError
      #pass
    end # begin
  end

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def run(output_queue)
    if server?
      @thread = Thread.current
      @client_threads = []
      loop do
        # Start a new thread for each connection.
        begin
          @client_threads << Thread.start(@server_socket.accept) do |s|
            # TODO(sissel): put this block in its own method.

            @logger.debug("Accepted connection",
                          :server => "#{@path}")
            begin
              handle_socket(s, output_queue)
            rescue Interrupted
              s.close rescue nil
            end
          end # Thread.start
        rescue IOError, Interrupted
          if @interrupted
            # Intended shutdown, get out of the loop
            @server_socket.close
            @client_threads.each do |thread|
              thread.raise(IOError.new)
            end
            break
          else
            # Else it was a genuine IOError caused by something else, so propagate it up..
            raise
          end
        end
      end # loop
    else
      loop do
        client_socket = UNIXSocket.new(@path)
        client_socket.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Opened connection", :client => @path)
        handle_socket(client_socket, output_queue)
      end # loop
    end
  end # def run

  public
  def teardown
    if server?
      File.unlink(@path)
      @interrupted = true
      @thread.raise(Interrupted.new)
    end
  end # def teardown
end # class LogStash::Inputs::Unix
