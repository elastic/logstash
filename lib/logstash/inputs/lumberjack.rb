require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "socket"
require "timeout"

# Receive events using the lumberjack protocol.
#
# NOTE: THIS PROTOCOL IS STILL A WORK IN PROGRESS
class LogStash::Inputs::Lumberjack < LogStash::Inputs::Base

  config_name "lumberjack"
  plugin_status "experimental"

  # the address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # the port to listen on.
  config :port, :validate => :number, :required => true

  public
  def register
    @logger.info("Starting lumberjack input listener", :address => "#{@host}:#{@port}")
    @server_socket = TCPServer.new(@host, @port)
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      last_ack = 0
      window_size = 2048

      # TODO(sissel): Update the protocol to announce window size from the
      # publisher.
      while true
        vf = socket.read(2)

        if vf != "1D" 
          logger.warn("Unexpected version/frame type", :vf => vf);
          socket.close
          return
        end

        # data frame
        sequence, count = socket.read(8).unpack("NN")
        map = {}
        count.times do 
          key_len = socket.read(4).unpack("N").first
          key = socket.read(key_len);
          value_len = socket.read(4).unpack("N").first
          value = socket.read(value_len);
          map[key] = value
        end

        if sequence - last_ack >= window_size
          # bulk ack, we've hit the window size
          socket.write(["1", "A", sequence].pack("AAN"))
          last_ack = sequence
        end

        event = LogStash::Event.new(
          "@type" => @type,
          "@tags" => (@tags.clone rescue []),
          "@source_path" => map["file"],
          "@source_host" => map["host"],
          "@source" => "lumberjack://#{map["host"]}#{map["file"]}",
          "@message" => map["line"]
        )
        output_queue << event
      end
    rescue StandardError => e
      @logger.warn("Closing connection", :client => socket.peer,
                    :exception => e, :backtrace => e.backtrace)
    end # begin
  ensure
    begin
      socket.close
    rescue IOError
      # ignore
    end # begin
  end # def handle_socket

  public
  def run(output_queue)
    loop do
      # Start a new thread for each connection.
      Thread.start(@server_socket.accept) do |s|
        # TODO(sissel): put this block in its own method.

        # monkeypatch a 'peer' method onto the socket.
        s.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Accepted connection", :client => s.peer,
                      :server => "#{@host}:#{@port}")
        handle_socket(s, output_queue, "lumberjack://#{@host}:#{@port}/#{s.peer}")
      end # Thread.start
    end # loop
  end # def run
end # class LogStash::Inputs::Tcp
