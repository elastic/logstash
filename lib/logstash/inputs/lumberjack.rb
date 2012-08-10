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

  # ssl certificate to use
  config :ssl_certificate, :validate => :string, :required => true

  # ssl key to use
  config :ssl_key, :validate => :string, :required => true

  # ssl key passphrase to use
  config :ssl_key_passphrase, :validate => :password

  # TODO(sissel): Add CA to authenticate clients with.

  public
  def register
    @logger.info("Starting lumberjack input listener", :address => "#{@host}:#{@port}")
    @tcp_server = TCPServer.new(@host, @port)

    ssl_context = OpenSSL::SSL::SSLContext.new
    begin
      cert_data = File.read(@ssl_certificate)
    rescue NameError, NoMethodError
      raise
    rescue => e
      @logger.error("Failed reading ssl certificate", :path => @ssl_certificate, :exception => e)
    end

    begin
      ssl_context.cert = OpenSSL::X509::Certificate.new(cert_data)
    rescue NameError, NoMethodError; raise
    rescue => e
      @logger.error("Failed parsing ssl certificate", :path => @ssl_certificate, :exception => e)
      raise
    end

    begin
      key_data = File.read(@ssl_key)
    rescue NameError, NoMethodError; raise
    rescue => e
      @logger.error("Failed reading ssl key file", :path => @ssl_key, :exception => e)
      raise
    end

    begin
      ssl_context.key = OpenSSL::PKey::RSA.new(key_data, @ssl_key_passphrase.value)
    rescue NameError, NoMethodError; raise
    rescue => e
      @logger.error("Failed parsing ssl key", :path => @ssl_key,
                    :passphrase? => !@ssl_key_passphrase.nil?, :exception => e)
      raise
    end

    @ssl_server = OpenSSL::SSL::SSLServer.new(server, ssl_context)
  end # def register

  private
  def handle_socket(socket, output_queue, event_source)
    begin
      last_ack = 0
      window_size = 1 # assume window size of 1 until told otherwise

      # TODO(sissel): Update the protocol to announce window size from the
      # publisher.
      while true
        vf = socket.read(2)

        if vf == "1W"
          window_size = socket.read(2).unpack("N").first
          next
        end

        if vf != "1D" 
          logger.warn("Unexpected version/frame type", :vf => vf);
          socket.close
          return
        end

        # We got a data frame, read the sequence, count of elements, then each
        # element.
        sequence, count = socket.read(8).unpack("NN")
        map = {}
        count.times do 
          key_len = socket.read(4).unpack("N").first
          key = socket.read(key_len);
          value_len = socket.read(4).unpack("N").first
          value = socket.read(value_len);
          map[key] = value
        end

        # bulk ack if we hit the window size
        if sequence - last_ack == window_size
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
      @logger.warn("Exception caught, closing connection", :client => socket.peer,
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
      Thread.start(@server.accept) do |client|
        # TODO(sissel): put this block in its own method.

        # monkeypatch a 'peer' method onto the socket.
        client.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Accepted connection", :client => client.peer,
                      :server => "#{@host}:#{@port}", :plugin => self)
        handle_socket(client, output_queue, "lumberjack://#{@host}:#{@port}/#{s.peer}")
      end # Thread.start
    end # loop
  end # def run
end # class LogStash::Inputs::Tcp
