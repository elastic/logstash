require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "timeout"

class LogStash::Inputs::Tcp < LogStash::Inputs::Base

  config_name "tcp"

  config :host, :validate => :string
  config :port, :validate => :number, :required => true
  config :data_timeout, :validate => :number

  public
  def initialize(params)
    super

    @host ||= "0.0.0.0"
    @data_timeout ||= 5
  end

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
            Timeout::timeout(@data_timeout) do
              buf = s.readline
            end
            e = LogStash::Event.new({
              "@message" => buf,
              "@type" => @type,
              "@tags" => @tags.clone,
            })
            e.source = "tcp://#{@host}:#{@port}/client/#{peer}"
            @logger.debug(["Received message from #{peer}"], e)
            output_queue << e
          end # loop do
        rescue
          @logger.debug("Closing connection with #{peer}")
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
