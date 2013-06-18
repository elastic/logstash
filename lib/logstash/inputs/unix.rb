require "logstash/inputs/base"
require "logstash/namespace"

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

  # When mode is `server`, the path to listen on.
  # When mode is `client`, the path to connect to.
  config :path, :validate => :string, :required => true

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
      @logger.info("Starting unix input listener", :address => "#{@path}")
      begin
        @server_socket = UNIXServer.new(@path)
      rescue Errno::EADDRINUSE
        @logger.error("Could not start UNIX server: Address in use",
                      :path => @path)
        raise
      end
    end
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

  private
  def readline(socket)
    line = socket.readline
  end # def readline

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
              handle_socket(s, output_queue, "unix://#{@path}/")
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
        @logger.debug("Opened connection", :client => "#{@path}")
        handle_socket(client_socket, output_queue, "unix://#{@path}/server")
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
