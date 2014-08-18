# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"

# Read events over a TCP socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
#
# Can either accept connections from clients or connect to a server,
# depending on `mode`.
class LogStash::Inputs::Tcp < LogStash::Inputs::Base
  class Interrupted < StandardError; end
  config_name "tcp"
  milestone 2

  default :codec, "line"

  # When mode is `server`, the address to listen on.
  # When mode is `client`, the address to connect to.
  config :host, :validate => :string, :default => "0.0.0.0"

  # When mode is `server`, the port to listen on.
  # When mode is `client`, the port to connect to.
  config :port, :validate => :number, :required => true

  # The 'read' timeout in seconds. If a particular tcp connection is idle for
  # more than this timeout period, we will assume it is dead and close it.
  #
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => -1

  # Mode to operate in. `server` listens for client connections,
  # `client` connects to a server.
  config :mode, :validate => ["server", "client"], :default => "server"

  # Enable SSL (must be set for other `ssl_` options to take effect).
  config :ssl_enable, :validate => :boolean, :default => false

  # Verify the identity of the other end of the SSL connection against the CA.
  # For input, sets the field `sslsubject` to that of the client certificate.
  config :ssl_verify, :validate => :boolean, :default => false

  # The SSL CA certificate, chainfile or CA path. The system CA path is automatically included.
  config :ssl_cacert, :validate => :path

  # SSL certificate path
  config :ssl_cert, :validate => :path

  # SSL key path
  config :ssl_key, :validate => :path

  # SSL key passphrase
  config :ssl_key_passphrase, :validate => :password, :default => nil

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    require "socket"
    require "timeout"
    require "openssl"

    # monkey patch TCPSocket and SSLSocket to include socket peer
    TCPSocket.module_eval{include ::LogStash::Util::SocketPeer}
    OpenSSL::SSL::SSLSocket.module_eval{include ::LogStash::Util::SocketPeer}

    fix_streaming_codecs

    if @ssl_enable
      @ssl_context = OpenSSL::SSL::SSLContext.new
      @ssl_context.cert = OpenSSL::X509::Certificate.new(File.read(@ssl_cert))
      @ssl_context.key = OpenSSL::PKey::RSA.new(File.read(@ssl_key),@ssl_key_passphrase)
      if @ssl_verify
        @cert_store = OpenSSL::X509::Store.new
        # Load the system default certificate path to the store
        @cert_store.set_default_paths
        if File.directory?(@ssl_cacert)
          @cert_store.add_path(@ssl_cacert)
        else
          @cert_store.add_file(@ssl_cacert)
        end
        @ssl_context.cert_store = @cert_store
        @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER|OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      end
    end # @ssl_enable

    if server?
      @logger.info("Starting tcp input listener", :address => "#{@host}:#{@port}")
      begin
        @server_socket = TCPServer.new(@host, @port)
      rescue Errno::EADDRINUSE
        @logger.error("Could not start TCP server: Address in use", :host => @host, :port => @port)
        raise
      end
      if @ssl_enable
        @server_socket = OpenSSL::SSL::SSLServer.new(@server_socket, @ssl_context)
      end # @ssl_enable
    end
  end # def register

  private
  def handle_socket(socket, client_address, output_queue, codec)
    while true
      buf = nil
      # NOTE(petef): the timeout only hits after the line is read or socket dies
      # TODO(sissel): Why do we have a timeout here? What's the point?
      if @data_timeout == -1
        buf = read(socket)
      else
        Timeout::timeout(@data_timeout) do
          buf = read(socket)
        end
      end
      codec.decode(buf) do |event|
        event["host"] ||= client_address
        event["sslsubject"] ||= socket.peer_cert.subject if @ssl_enable && @ssl_verify
        decorate(event)
        output_queue << event
      end
    end # loop
  rescue EOFError
    @logger.debug? && @logger.debug("Connection closed", :client => socket.peer)
  rescue Errno::ECONNRESET
    @logger.debug? && @logger.debug("Connection reset by peer", :client => socket.peer)
  rescue => e
    @logger.error("An error occurred. Closing connection", :client => socket.peer, :exception => e, :backtrace => e.backtrace)
  ensure
    socket.close rescue nil

    codec.respond_to?(:flush) && codec.flush do |event|
      event["host"] ||= client_address
      event["sslsubject"] ||= socket.peer_cert.subject if @ssl_enable && @ssl_verify
      decorate(event)
      output_queue << event
    end
  end

  private
  def client_thread(output_queue, socket)
    Thread.new(output_queue, socket) do |q, s|
      begin
        @logger.debug? && @logger.debug("Accepted connection", :client => s.peer, :server => "#{@host}:#{@port}")
        handle_socket(s, s.peer, q, @codec.clone)
      rescue Interrupted
        s.close rescue nil
      ensure
        @client_threads_lock.synchronize{@client_threads.delete(Thread.current)}
      end
    end
  end

  private
  def server?
    @mode == "server"
  end # def server?

  private
  def read(socket)
    return socket.sysread(16384)
  end # def readline

  public
  def run(output_queue)
    if server?
      run_server(output_queue)
    else
      run_client(output_queue)
    end
  end # def run

  def run_server(output_queue)
    @thread = Thread.current
    @client_threads = []
    @client_threads_lock = Mutex.new

    while true
      begin
        socket = @server_socket.accept
        # start a new thread for each connection.
        @client_threads_lock.synchronize{@client_threads << client_thread(output_queue, socket)}
      rescue OpenSSL::SSL::SSLError => ssle
        # NOTE(mrichar1): This doesn't return a useful error message for some reason
        @logger.error("SSL Error", :exception => ssle, :backtrace => ssle.backtrace)
      rescue IOError, LogStash::ShutdownSignal
        if @interrupted
          @server_socket.close rescue nil

          threads = @client_threads_lock.synchronize{@client_threads.dup}
          threads.each do |thread|
            thread.raise(LogStash::ShutdownSignal) if thread.alive?
          end

          # intended shutdown, get out of the loop
          break
        else
          # it was a genuine IOError, propagate it up
          raise
        end
      end
    end # loop
  rescue LogStash::ShutdownSignal
    # nothing to do
  ensure
    @server_socket.close rescue nil
  end # def run_server

  def run_client(output_queue)
    @thread = Thread.current
    while true
      client_socket = TCPSocket.new(@host, @port)
      if @ssl_enable
        client_socket = OpenSSL::SSL::SSLSocket.new(client_socket, @ssl_context)
        begin
          client_socket.connect
        rescue OpenSSL::SSL::SSLError => ssle
          @logger.error("SSL Error", :exception => ssle, :backtrace => ssle.backtrace)
          # NOTE(mrichar1): Hack to prevent hammering peer
          sleep(5)
          next
        end
      end
      @logger.debug("Opened connection", :client => "#{client_socket.peer}")
      handle_socket(client_socket, client_socket.peer, output_queue, @codec.clone)
    end # loop
  ensure
    client_socket.close rescue nil
  end # def run

  public
  def teardown
    if server?
      @interrupted = true
    end
  end # def teardown
end # class LogStash::Inputs::Tcp
