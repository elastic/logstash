require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "socket"
require "timeout"
#TODO: make sure to remove this before release
#require "pry"

# Read RELP events over a TCP socket.
#
#
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
    @server_socket = TCPServer.new(@host, @port)
  end # def register

  #give it a socket, it'll wait for a relp open frame and do the handshake
  private
  def relp_initialise(socket)
    # Throw away everything until we find a RELP frame with open command
    frame=parse_relp_frame(socket) until !frame.nil? && frame['command']=='open'
    @logger.debug("Recieved relp offer: #{frame.to_s}")
    offer=Hash[*frame['message'].scan(/^(.*)=(.*)$/).flatten]
    if offer['relp_version'].nil?
      #TODO: if no version specified, relp spec says we must close connection
    elsif ! offer['commands'].split(',').include?('syslog')
      #TODO: if it can't send us syslog it's useless to us; close the connection
    else
      #attempt to set up connection
#TODO: assemble the response properly
      socket.write('1 rsp 86 200 OK relp_version=0'+"\n"+'relp_software=logstash,1.0.0,http://logstash.net'+"\n"+'commands=syslog'+"\n")
    end
#TODO: give a meaningful return value
  end

  private
  def relp_stream(socket,output_queue,event_source)
    loop do
      frame=parse_relp_frame(socket)
      if frame['command']=='syslog'
        #hooray, we have a syslog line TODO: actually process it
        event=self.to_event(frame['message'],event_source)
        output_queue << event
        #To get this far, the message must have made it into the queue for filtering. I don't think it's possible to wait for output before ack without fundamentally breaking the plugin architecture
        relp_ack(socket,frame['txnr'])
      elsif frame['command']=='close'
        #the client is closing the connection, TODO: do something useful
      else
        #the client is trying to do something else, run around like a headless chicken
      end
    end
  end

  private
  def parse_relp_frame(socket)
    frame=Hash.new
    frame['txnr']=socket.readline(' ').strip.to_i
    frame['command']=socket.readline(' ').strip
    frame['datalen']=socket.readline(' ').strip.to_i
    frame['message']=socket.read(frame['datalen'])
    frame
  end

  #send a 200 OK response for txnr to socket
  private
  def relp_ack(socket,txnr)
    #TODO: build this in a more readable way. write a relp frame assembler/sender?
    data=txnr.to_s+' 200 OK'
    socket.write(txnr.to_s+' rsp '+data.length.to_s+' '+data+"\n")
  end

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
        begin
          relp_initialise(s)
#TODO: proper event_source
          relp_stream(s,output_queue,'relp@localhost')
#TODO: deal with stream unexpectedly closing
        rescue
          puts 'rescue'
        end
      end # Thread.start
    end # loop
  end # def run
end # class LogStash::Inputs::Tcp
