require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/relp"


# Read RELP events over a TCP socket.
#
#Application level acknowledgements allow assurance of no message loss.
#
#This only functions as far as messages being put into the queue for filters- 
# anything lost after that point will not be retransmitted
class LogStash::Inputs::Relp < LogStash::Inputs::Base

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
  def relp_stream(relpsocket,output_queue,event_source)
    loop do
      frame = relpsocket.syslog_read
      event = self.to_event(frame['message'],event_source)
      output_queue << event
      #To get this far, the message must have made it into the queue for 
      #filtering. I don't think it's possible to wait for output before ack
      #without fundamentally breaking the plugin architecture
      relpsocket.ack(frame['txnr'])
    end
  end

  public
  def run(output_queue)
    loop do
      begin
        # Start a new thread for each connection.
        Thread.start(@relp_server.accept) do |rs|
            @logger.debug("Relp Connection to #{rs.peer} created")
          begin
            relp_stream(rs,output_queue,"relp://#{@host}:#{@port}/#{rs.peer}")
          rescue Relp::ConnectionClosed => e
            @logger.debug("Relp Connection to #{rs.peer} Closed")
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
      end
    end # loop
  end # def run

  def teardown
    @relp_server.shutdown
  end
end # class LogStash::Inputs::Relp

#TODO: structured error logging
