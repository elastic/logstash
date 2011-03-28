require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Tcp < LogStash::Outputs::Base

  config_name "tcp"

  config :host, :validate => :string, :required => true
  config :port, :validate => :number, :required => true

  public
  def initialize(params)
    super
  end # def initialize

  public
  def register
    @socket = nil
  end # def register

  private
  def connect
    @socket = TCPSocket.new(@host, @port)
  end

  public
  def receive(event)
    begin
      connect unless @socket
      @socket.write(event.to_hash.to_json)
      @socket.write("\n")
    rescue
      @logger.warn(["tcp output exception", @host, @port, $!])
      @socket = nil
    end
  end # def receive
end # class LogStash::Outputs::Tcp
