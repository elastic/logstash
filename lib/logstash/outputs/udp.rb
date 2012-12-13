require "logstash/outputs/base"
require "logstash/namespace"
require "thread"


# Write events over a UDP socket.
#
# Each event json is separated by a newline.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Outputs::Udp < LogStash::Outputs::Base

  config_name "udp"
  plugin_status "experimental"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :required => true

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "client"

  config :raw, :validate => :boolean, :default => false

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
          @logger.warn("udp output exception", :socket => @socket,
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
      @logger.info("Starting udp output listener", :address => "#{@host}:#{@port}")
      @server_socket = UDPServer.new(@port)
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
    @da = Socket.pack_sockaddr_in(@port.to_i, @host)
    @client_socket = Socket.new Socket::PF_INET, Socket::SOCK_DGRAM
  end # def connect

  private
  def server?
    @mode == "server"
  end # def server?

  public
  def receive(event)
    @logger.info("message received to udp output plugin", event.to_hash)
    return unless output?(event)

    if server?
      @client_threads.each do |client_thread|
        if @raw then
          client_thread[:client].write(event.to_hash.to_s)
        else
          client_thread[:client].write(event)
        end
      end

      @client_threads.reject! {|t| !t.alive? }
    else
      begin
        connect unless @client_socket
        @client_socket.send(event.message, 0, @da)
      rescue => e
        @logger.warn("udp output exception", :host => @host, :port => @port,
                     :exception => e, :backtrace => e.backtrace)
        @client_socket = nil
      end
    end
  end # def receive
end # class LogStash::Outputs::Udp
