require "logstash/inputs/base"
require "logstash/namespace"
require "logstash/util/socket_peer"
require "socket"
require "timeout"
#TODO: remove before release
require "pry"

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

  private
  def relp_stream(relpsocket,output_queue,event_source)
    loop do
      frame=relpsocket.syslog_read
      event=self.to_event(frame['message'],event_source)
      output_queue << event
      #To get this far, the message must have made it into the queue for filtering. I don't think it's possible to wait for output before ack without fundamentally breaking the plugin architecture
      relpsocket.ack(frame['txnr'])
    end
  end

  public
  def run(output_queue)
    loop do
      # Start a new thread for each connection.
      Thread.start(@server_socket.accept) do |s|

        # monkeypatch a 'peer' method onto the socket.
        s.instance_eval { class << self; include ::LogStash::Util::SocketPeer end }
        @logger.debug("Accepted connection", :client => s.peer,
                      :server => "#{@host}:#{@port}")
        begin
          rs=RelpSocket.new(s)
          relp_stream(rs,output_queue,"relp://#{@host}:#{@port}/s.peer")
          
        rescue Exception => e
          @logger.error('Unexpected error: '+e.message)
          #Relp spec says to close connection on error
          s.close
        end
      end # Thread.start
    end # loop
  end # def run
end # class LogStash::Inputs::Relp

class RelpSocket #TODO: Should this be a subclass of TCPSocket?

  class RelpError < StandardError; end
  class InvalidCommand < RelpError; end
  class InappropriateCommand < RelpError; end
  class ConnectionClosed < RelpError; end #TODO: should this be handled as an exception?
  
  def initialize(socket)
    @socket=socket
    frame=self.frame_read
    if frame['command']=='open'
      offer=Hash[*frame['message'].scan(/^(.*)=(.*)$/).flatten]
      if offer['relp_version'].nil?
        #if no version specified, relp spec says we must close connection
        self.serverclose
        Raise RelpError 'No relp_version specified'
      elsif ! offer['commands'].split(',').include?('syslog')
        #if it can't send us syslog it's useless to us; close the connection TODO:Generalise relp class and make this optional
        self.serverclose
        Raise RelpError 'Relp client incapable of syslog'
      else
        #attempt to set up connection
        response_frame=Hash.new
        response_frame['txnr']=frame['txnr']
        response_frame['command']='rsp'
        #TODO: the values in this message probably ought to be constants defined at the top somewhere
        response_frame['message']='200 OK relp_version=0'+"\n"+'relp_software=logstash,1.0.0,http://logstash.net'+"\n"+'commands=syslog'
        begin
          self.frame_write(response_frame)
        rescue
          Raise ConnectionClosed#TODO:should I really be handling it like this? surely a general catchall somewhere for connection errors is a better idea?
        end
      end
    elsif RelpSocket.valid_command?(frame['command'])
        Raise InappropriateCommand frame['command']+' expecting open'
    else
        Raise InvalidCommand frame['command']
    end
  end

  def frame_write(frame)
    frame['txnr']=frame['txnr'].to_s
    frame['message']='' if frame['message'].nil?
    frame['datalen']=frame['message'].length.to_s
    #Ending each frame with a newline is required in the specifications
    wiredata=[frame['txnr'],frame['command'],frame['datalen'],frame['message']].join(' ').strip+"\n"
    @socket.write(wiredata)
  end

  #This does not ack the frame, just reads it
  def syslog_read
    frame=self.frame_read
    if frame['command']=='syslog'
      return frame
    elsif frame['command']=='close'
      #the client is closing the connection, acknowledge the close and act on it
      response_frame=Hash.new
      response_frame['txnr']=frame['txnr']
      response_frame['command']='rsp'
      self.frame_write(response_frame)
      self.serverclose
      raise ConnectionClosed
    else
      #the client is trying to do something unexpected
      self.serverclose
      #This should deal with framing errors/invalid input most of the time; TODO: look at being more stringent somewhere
      if RelpSocket.valid_command?(frame['command'])
        Raise InappropriateCommand frame['command']+' expecting syslog'
      else
        Raise InvalidCommand frame['command']
      end
    end
  end


  def serverclose
    frame=Hash.new
    frame['txnr']=0
    frame['command']='serverclose'
    begin
      peer=@socket.peer
      self.frame_write(frame)
      @socket.close
      raise ConnectionClosed
    rescue
      raise ConnectionClosed #This catches the possibility of the client having already closed the connection
    end
  end

  def self.valid_command?(command)
    valid_commands=Array.new
    valid_commands << 'open'
    valid_commands << 'close'
    valid_commands << 'syslog'
    #Don't accept serverclose or rsp as valid commands because this is the server
    #TODO: vague mentions of abort and starttls commands in spec need looking into
    return valid_commands.include?(command)
  end

  def frame_read
    frame=Hash.new
    frame['txnr']=@socket.readline(' ').strip.to_i
    frame['command']=@socket.readline(' ').strip

    #Things get a little tricky here because if the length is 0 it is not followed by a space.
    leading_digit=@socket.read(1)
    if leading_digit=='0' then
      frame['datalen']=0
      frame['message']=''
    else
      frame['datalen']=(leading_digit + @socket.readline(' ')).strip.to_i
      frame['message']=@socket.read(frame['datalen'])
    end
#TODO: check here for invalid commands to try to detect framing errors?
    return frame
  end

  def ack(txnr)
    frame=Hash.new
    frame['txnr']=txnr
    frame['command']='rsp'
    frame['message']='200 OK'
    self.frame_write(frame)
  end

end

