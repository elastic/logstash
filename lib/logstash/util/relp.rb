require "socket"

class Relp#This isn't much use on its own, but gives RelpServer and RelpClient things

  RelpVersion='0'#TODO: spec says this is experimental, but rsyslog still seems to exclusively use it
  RelpSoftware='logstash,1.1.1,http://logstash.net'#TODO: this is a placeholder for now
  RelpCommands=['syslog']#TODO: If this becomes a separate gem, make this variable, define required and optional ones

  class RelpError < StandardError; end
  class InvalidCommand < RelpError; end
  class InappropriateCommand < RelpError; end
  class ConnectionClosed < RelpError; end 

  def self.valid_command?(command)
    valid_commands=Array.new
    
    #Allow anything in the basic protocol
    valid_commands << 'open'
    valid_commands << 'close'
    valid_commands << 'rsp'

    #Allow anything we offered to accept
    valid_commands += RelpCommands
    #Don't accept serverclose or rsp as valid commands because this is the server TODO: generalise
    #TODO: vague mentions of abort and starttls commands in spec need looking into
    return valid_commands.include?(command)
  end

  #TODO: this only makes sense for RelpClient; RelpServer can only use the txnr of the frame it's replying to or 0
  def nexttxnr
    @lasttxnr+=1
  end

  def frame_write(frame)
    frame['txnr']=self.nexttxnr if frame['txnr'].nil?
    frame['txnr']=frame['txnr'].to_s
    frame['message']='' if frame['message'].nil?
    frame['datalen']=frame['message'].length.to_s
    #Ending each frame with a newline is required in the specifications
    wiredata=[frame['txnr'],frame['command'],frame['datalen'],frame['message']].join(' ').strip+"\n"
    begin
      @socket.write(wiredata)
    rescue Errno::EPIPE#TODO: is this sufficient to catch all broken connections?
      raise ConnectionClosed
    end
    frame['txnr'].to_i
  end

  def frame_read
    begin
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
    rescue EOFError
      raise ConnectionClosed #TODO: ECONNRESET
    end
    if ! Relp.valid_command?(frame['command'])#TODO: is this enough to catch framing errors? 
      raise InvalidCommand,frame['command']
    end
    return frame
  end

end

class RelpServer < Relp

  def peer
    @socket.peeraddr[3]#TODO: is this the best thing to report?
  end

  def initialize(host,port)
    @server=TCPServer.new(host,port)
  end
  
  def accept
    @socket=@server.accept
    frame=self.frame_read
    if frame['command']=='open'
      offer=Hash[*frame['message'].scan(/^(.*)=(.*)$/).flatten]
      if offer['relp_version'].nil?
        #if no version specified, relp spec says we must close connection
        self.serverclose
        raise RelpError, 'No relp_version specified'
      elsif ! offer['commands'].split(',').include?('syslog')
        #if it can't send us syslog it's useless to us; close the connection 
        #TODO:Generalise relp class and make this optional (related to RelpCommands)
        self.serverclose
        raise RelpError, 'Relp client incapable of syslog'
      else
        #attempt to set up connection
        response_frame=Hash.new
        response_frame['txnr']=frame['txnr']
        response_frame['command']='rsp'

        response_frame['message']='200 OK '
        response_frame['message']+='relp_version='+RelpVersion+"\n"
        response_frame['message']+='relp_software='+RelpSoftware+"\n"
        response_frame['message']+='commands='+RelpCommands.join(',')
        self.frame_write(response_frame)
        return self
      end
      raise InappropriateCommand, frame['command']+' expecting open'

    end
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
      raise InappropriateCommand, frame['command']+' expecting syslog'
    end
  end

  def serverclose
    frame=Hash.new
    frame['txnr']=0
    frame['command']='serverclose'
    begin
      self.frame_write(frame)
      @socket.close#TODO: shutdown?
    rescue#This catches the possibility of the client having already closed the connection
    end
  end

  def ack(txnr)
    frame=Hash.new
    frame['txnr']=txnr
    frame['command']='rsp'
    frame['message']='200 OK'
    self.frame_write(frame)
  end
end

class RelpClient < Relp

  def initialize(host,port)
    @socket=TCPSocket.new(host,port)
    offer=Hash.new
    offer['txnr']=1
    offer['command']='open'
    offer['message']='relp_version='+RelpVersion+"\n"
    offer['message']+='relp_software='+RelpSoftware+"\n"
    offer['message']+='commands='+RelpCommands.join(',')
    self.frame_write(offer)
    response_frame=self.frame_read
    raise RelpError if response_frame['message'][0,3]!='200' 
    response=Hash[*response_frame['message'][7..-1].scan(/^(.*)=(.*)$/).flatten]
    if response['relp_version'].nil?
      #if no version specified, relp spec says we must close connection
      self.close
      raise RelpError, 'No relp_version specified; offer: ',response_frame['message'][6..-1].scan(/^(.*)=(.*)$/).flatten
    elsif ! response['commands'].split(',').include?('syslog')
      #if it can't receive syslog it's useless to us; close the connection 
      #TODO:Generalise relp class and make this optional (related to RelpCommands)
      self.close
      raise RelpError, 'Relp server incapable of syslog'
    end
    #If we've got this far with no problems, we're good to go
    @lasttxnr=1

    #TODO: This allows us to keep track of what acks have been recieved. What this interface looks like and how to handle acks needs thinking about
    @replies=Hash.new
    Thread.start do
      loop do
        f=self.frame_read
        @replies[f['txnr'].to_i]=f['message']
        if f['command']=='serverclose'
          #Give other threads a bit of time to act on acks. TODO: feels a bit dodgy
          sleep 1
          raise ConnectionClosed
        end
      end
    end
  end

  def close
    frame=Hash.new
    frame['command']='close'
    txnr=self.frame_write(frame)
    #TODO: timeout
    sleep 0.01 until ! @replies[txnr].nil?
    #Give other threads a bit of time to act on acks. TODO: feels a bit dodgy
    sleep 1
    @socket.close#TODO: shutdown? 
  end

  #This will block until it can confirm a reply, but is written so multiple threads can call it concurrently
  def syslog_write(logline)
    frame=Hash.new
    frame['command']='syslog'
    frame['message']=logline
    txnr=self.frame_write(frame)

    #This could potentially block indefinately, TODO: is this a good idea?
    #TODO: resend if no ack after too long, raise an exception if this fails multiple times?
    sleep 0.01 until ! @replies[txnr].nil?
    reply=@replies.delete(txnr)
    raise RelpError,reply unless reply=='200 OK'
  end
end
