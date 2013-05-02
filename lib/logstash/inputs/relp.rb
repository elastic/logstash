require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/relp"
require "logstash/util/socket_peer"


# Read RELP events over a TCP socket.
#
# For more information about RELP, see 
# <http://www.rsyslog.com/doc/imrelp.html>
#
# This protocol implements application-level acknowledgements to help protect
# against message loss.
#
# Message acks only function as far as messages being put into the queue for
# filters; anything lost after that point will not be retransmitted
class LogStash::Inputs::Relp < LogStash::Inputs::Base
  class Interrupted < StandardError; end

  config_name "relp"
  plugin_status "experimental"

  # The address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on.
  config :port, :validate => :number, :required => true

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    @logger.info("Starting relp input listener", :address => "#{@host}:#{@port}")
    @relp_server = RelpServer.new(@host, @port,['syslog'])
  end # def register

  private
  def relp_stream(relpserver,socket,output_queue,event_source)
    loop do
      frame = relpserver.syslog_read(socket)
      event = self.to_event(frame['message'],event_source)
      output_queue << event
      #To get this far, the message must have made it into the queue for 
      #filtering. I don't think it's possible to wait for output before ack
      #without fundamentally breaking the plugin architecture
      relpserver.ack(socket, frame['txnr'])
    end
  end

  public
  def run(output_queue)
    @thread = Thread.current
    loop do
      begin
        # Start a new thread for each connection.
        Thread.start(@relp_server.accept) do |client|
            rs = client[0]
            socket = client[1]
            # monkeypatch a 'peer' method onto the socket.
            socket.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
            peer = socket.peer
            @logger.debug("Relp Connection to #{peer} created")
          begin
            relp_stream(rs,socket, output_queue,"relp://#{peer}")
          rescue Relp::ConnectionClosed => e
            @logger.debug("Relp Connection to #{peer} Closed")
          rescue Relp::RelpError => e
            @logger.warn('Relp error: '+e.class.to_s+' '+e.message)
            #TODO: Still not happy with this, are they all warn level?
            #Will this catch everything I want it to?
            #Relp spec says to close connection on error, ensure this is the case
          end
        end # Thread.start
      rescue Relp::InvalidCommand,Relp::InappropriateCommand => e
        @logger.warn('Relp client trying to open connection with something other than open:'+e.message)
      rescue Relp::InsufficientCommands
        @logger.warn('Relp client incapable of syslog')
      rescue IOError, Interrupted
        if @interrupted
          # Intended shutdown, get out of the loop
          @relp_server.shutdown
          break
        else
          # Else it was a genuine IOError caused by something else, so propagate it up..
          raise
        end
      end
    end # loop
  end # def run

  def teardown
    @interrupted = true
    @thread.raise(Interrupted.new)
  end
end # class LogStash::Inputs::Relp

#TODO: structured error logging
