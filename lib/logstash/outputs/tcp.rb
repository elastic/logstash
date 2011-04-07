require "logstash/outputs/base"
require "logstash/namespace"

# This output writes each event in json format to 
# the specified host:port over tcp.
#
# Each event json is separated by a newline.
class LogStash::Outputs::Tcp < LogStash::Outputs::Base

  config_name "tcp"

  # The host to connect to
  config :host, :validate => :string, :required => true

  # The port to connect to
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
