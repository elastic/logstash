require "logstash/outputs/base"
require "logstash/namespace"
require "thread"


# Write events over a TCP socket.
#
# Each event json is separated by a newline.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Outputs::Tcp < LogStash::Outputs::Base

  config_name "tcp"
  milestone 2

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :required => true

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "client"

  # The format to use when writing events to the file. This value
  # supports any string and can include %{name} and other dynamic
  # strings.
  #
  # If this setting is omitted, the full json representation of the
  # event will be written as a single line.
  config :message_format, :validate => :string

  class Client
    public
    def initialize(socket, logger)
      @socket = socket
      @logger = logger
      @queue  = Queue.new
    end

    public
    def run
      loop do
        begin
          @socket.write(@queue.pop)
        rescue => e
          @logger.warn("tcp output exception", :socket => @socket,
                       :exception => e, :backtrace => e.backtrace)
          break
        end
      end
    end # def run

    public
    def write(msg)
      @queue.push(msg)
    end # def write
  end # class Client

  public
  def register
    if server?
      @logger.info("Starting tcp output listener", :address => "#{@host}:#{@port}")
      @server_socket = TCPServer.new(@host, @port)
      @client_threads = []

      @accept_thread = Thread.new(@server_socket) do |server_socket|
        loop do
          client_thread = Thread.start(server_socket.accept) do |client_socket|
            client = Client.new(client_socket, @logger)
            Thread.current[:client] = client
            client.run
          end
          @client_threads << client_thread
        end
      end
    else
      @client_socket = nil
    end
  end # def register

  private
  def connect
    @client_socket = TCPSocket.new(@host, @port)
  end # def connect

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def receive(event)
    return unless output?(event)

    if @message_format
      output = event.sprintf(@message_format) + "\n"
    else
      output = event.to_hash.to_json + "\n"
    end

    if server?
      @client_threads.each do |client_thread|
        client_thread[:client].write(output)
      end

      @client_threads.reject! {|t| !t.alive? }
    else
      begin
        connect unless @client_socket
        @client_socket.write(output)
      rescue => e
        @logger.warn("tcp output exception", :host => @host, :port => @port,
                     :exception => e, :backtrace => e.backtrace)
        @client_socket = nil
      end
    end
  end # def receive
end # class LogStash::Outputs::Tcp
