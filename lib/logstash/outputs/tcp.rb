require "logstash/outputs/base"
require "logstash/namespace"
require "thread"

# This output writes each event in json format to
# the specified host:port over tcp.
#
# Each event json is separated by a newline.
class LogStash::Outputs::Tcp < LogStash::Outputs::Base

  config_name "tcp"

  # The host to connect or bind to
  config :host, :validate => :string, :required => true

  # The port to connect or bind to
  config :port, :validate => :number, :required => true

  # Enable server.
  config :server, :validate => :boolean

  class Client < Thread
    def initialize(socket)
      @socket = socket
      @queue  = Queue.new

      super do
        loop do
          begin
            @socket.write(@queue.pop)
          rescue => e
            @logger.warn(["tcp output exception", @socket, $!])
            @logger.debug(["backtrace", e.backtrace])
            break
          end
        end
      end
    end

    def write(msg)
      @queue.push(msg)
    end
  end

  public
  def register
    if @server
      @logger.info("Starting tcp output listener on #{@host}:#{@port}")
      @server_socket = TCPServer.new(@host, @port)
      @client_threads = []

      @accept_thread = Thread.new(@server_socket) do |server|
        loop do
          @client_threads << Client.new(server.accept)
        end
      end
    else
      @socket = nil
    end
  end # def register

  private
  def connect
    @socket = TCPSocket.new(@host, @port)
  end

  public
  def receive(event)
    wire_event = event.to_hash.to_json + "\n"

    if @server
      @client_threads.each do |client_thread|
        client_thread.write(wire_event)
      end

      @client_threads.reject! {|t| !t.alive? }
    else
      begin
        connect unless @socket
        @socket.write(event.to_hash.to_json)
        @socket.write("\n")
      rescue => e
        @logger.warn(["tcp output exception", @host, @port, $!])
        @logger.debug(["backtrace", e.backtrace])
        @socket = nil
      end
    end
  end # def receive
end # class LogStash::Outputs::Tcp
