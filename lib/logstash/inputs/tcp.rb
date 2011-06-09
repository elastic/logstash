require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "timeout"

# Read events over a TCP socket.
#
# Like stdin and file inputs, each event is assumed to be one line of text.
class LogStash::Inputs::Tcp < LogStash::Inputs::Base

  config_name "tcp"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"
  
  # the port to listen on
  config :port, :validate => :number, :required => true

  # Read timeout in seconds. If a particular tcp connection is
  # idle for more than this timeout period, we will assume 
  # it is dead and close it.
  # If you never want to timeout, use -1.
  config :data_timeout, :validate => :number, :default => 5

  public
  def register
    @logger.info("Starting tcp listener on #{@host}:#{@port}")
    @server = TCPServer.new(@host, @port)
  end # def register

  public
  def run(output_queue)
    loop do
      # Start a new thread for each connection.
      Thread.start(@server.accept) do |s|
        # TODO(sissel): put this block in its own method.
        peer = "#{s.peeraddr[3]}:#{s.peeraddr[1]}"
        @logger.debug("Accepted connection from #{peer} on #{@host}:#{@port}")
        begin
          loop do
            buf = nil
            # NOTE(petef): the timeout only hits after the line is read
            # or socket dies
            # TODO(sissel): Why do we have a timeout here? What's the point?
            if @data_timeout == -1
              buf = s.readline
            else
              Timeout::timeout(@data_timeout) do
                buf = s.readline
              end
            end
            e = self.to_event(buf, "tcp://#{@host}:#{@port}/client/#{peer}")
            if e
              output_queue << e
            end
          end # loop do
        rescue => e
          @logger.debug(["Closing connection with #{peer}", $!])
          @logger.debug(["Backtrace", e.backtrace])
        rescue Timeout::Error
          @logger.debug("Closing connection with #{peer} after read timeout")
        end # begin

        begin
          s.close
        rescue IOError
          pass
        end # begin
      end # Thread.start
    end # loop (outer)
  end # def run
end # class LogStash::Inputs::Tcp
