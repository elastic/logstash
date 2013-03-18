require "socket"

class Relp#This isn't much use on its own, but gives RelpServer and RelpClient things

  RelpVersion = '0'#TODO: spec says this is experimental, but rsyslog still seems to exclusively use it
  RelpSoftware = 'logstash,1.1.1,http://logstash.net'

  class RelpError < StandardError; end
  class InvalidCommand < RelpError; end
  class InappropriateCommand < RelpError; end
  class ConnectionClosed < RelpError; end
  class InsufficientCommands < RelpError; end

  def valid_command?(command)
    valid_commands = Array.new
    
    #Allow anything in the basic protocol for both directions
    valid_commands << 'open'
    valid_commands << 'close'

    #These are things that are part of the basic protocol, but only valid in one direction (rsp, close etc.) TODO: would they be invalid or just innapropriate?
    valid_commands += @basic_relp_commands

    #These are extra commands that we require, otherwise refuse the connection TODO: some of these are only valid on one direction
    valid_commands += @required_relp_commands

    #TODO: optional_relp_commands

    #TODO: vague mentions of abort and starttls commands in spec need looking into
    return valid_commands.include?(command)
  end

  def frame_write(socket, frame)
    unless self.server? #I think we have to trust a server to be using the correct txnr
      #Only allow txnr to be 0 or be determined automatically
      frame['txnr'] = self.nexttxnr() unless frame['txnr']==0
    end
    frame['txnr'] = frame['txnr'].to_s
    frame['message'] = '' if frame['message'].nil?
    frame['datalen'] = frame['message'].length.to_s
    wiredata=[
      frame['txnr'],
      frame['command'],
      frame['datalen'],
      frame['message']
    ].join(' ').strip
    begin
      @logger.debug? and @logger.debug("Writing to socket", :data => wiredata)
      socket.write(wiredata)
      #Ending each frame with a newline is required in the specifications
      #Doing it a separately is useful (but a bit of a bodge) because
      #for some reason it seems to take 2 writes after the server closes the
      #connection before we get an exception
      socket.write("\n")
    rescue Errno::EPIPE,IOError,Errno::ECONNRESET#TODO: is this sufficient to catch all broken connections?
      raise ConnectionClosed
    end
    return frame['txnr'].to_i
  end

  def frame_read(socket)
    begin
      frame = Hash.new
      frame['txnr'] = socket.readline(' ').strip.to_i
      frame['command'] = socket.readline(' ').strip

      #Things get a little tricky here because if the length is 0 it is not followed by a space.
      leading_digit=socket.read(1)
      if leading_digit=='0' then
        frame['datalen'] = 0
        frame['message'] = ''
      else
        frame['datalen'] = (leading_digit + socket.readline(' ')).strip.to_i
        frame['message'] = socket.read(frame['datalen'])
      end
      @logger.debug? and @logger.debug("Read frame", :frame => frame)
    rescue EOFError,Errno::ECONNRESET,IOError
      raise ConnectionClosed
    end
    if ! self.valid_command?(frame['command'])#TODO: is this enough to catch framing errors?
      if self.server?
        self.serverclose
      else
        self.close
      end
      raise InvalidCommand,frame['command']
    end
    return frame
  end

  def server?
    @server
  end

end

class RelpServer < Relp

  def initialize(host,port,required_commands=[])
    @logger = Cabin::Channel.get(LogStash)
    
    @server=true

    #These are things that are part of the basic protocol, but only valid in one direction (rsp, close etc.)
    @basic_relp_commands = ['close']#TODO: check for others

    #These are extra commands that we require, otherwise refuse the connection
    @required_relp_commands = required_commands

    begin
      @server = TCPServer.new(host, port)
    rescue Errno::EADDRINUSE
      @logger.error("Could not start RELP server: Address in use",
                    :host => host, :port => port)
      raise
    end
    @logger.info? and @logger.info("Started RELP Server", :host => host, :port => port)
  end

  def accept
    socket = @server.accept
    frame=self.frame_read(socket)
    if frame['command'] == 'open'
      offer=Hash[*frame['message'].scan(/^(.*)=(.*)$/).flatten]
      if offer['relp_version'].nil?
        @logger.warn("No relp version specified")
        #if no version specified, relp spec says we must close connection
        self.serverclose(socket)
        raise RelpError, 'No relp_version specified'
      #subtracting one array from the other checks to see if all elements in @required_relp_commands are present in the offer
      elsif ! (@required_relp_commands - offer['commands'].split(',')).empty?
        @logger.warn("Not all required commands are available", :required => @required_relp_commands, :offer => offer['commands'])
        #Tell them why we're closing the connection:
        response_frame = Hash.new
        response_frame['txnr'] = frame['txnr']
        response_frame['command'] = 'rsp'
        response_frame['message'] = '500 Required command(s) '
            + (@required_relp_commands - offer['commands'].split(',')).join(',')
            + ' not offered'
        self.frame_write(socket,response_frame)
        self.serverclose(socket)
        raise InsufficientCommands, offer['commands']
            + ' offered, require ' + @required_relp_commands.join(',')
      else
        #attempt to set up connection
        response_frame = Hash.new
        response_frame['txnr'] = frame['txnr']
        response_frame['command'] = 'rsp'

        response_frame['message'] = '200 OK '
        response_frame['message'] += 'relp_version=' + RelpVersion + "\n"
        response_frame['message'] += 'relp_software=' + RelpSoftware + "\n"
        response_frame['message'] += 'commands=' + @required_relp_commands.join(',')#TODO: optional ones
        self.frame_write(socket, response_frame)
        return self, socket
      end
    else
      self.serverclose(socket)
      raise InappropriateCommand, frame['command'] + ' expecting open'
    end
  end

  #This does not ack the frame, just reads it
  def syslog_read(socket)
    frame = self.frame_read(socket)
    if frame['command'] == 'syslog'
      return frame
    elsif frame['command'] == 'close'
      #the client is closing the connection, acknowledge the close and act on it
      response_frame = Hash.new
      response_frame['txnr'] = frame['txnr']
      response_frame['command'] = 'rsp'
      self.frame_write(socket,response_frame)
      self.serverclose(socket)
      raise ConnectionClosed
    else
      #the client is trying to do something unexpected
      self.serverclose(socket)
      raise InappropriateCommand, frame['command'] + ' expecting syslog'
    end
  end

  def serverclose(socket)
    frame = Hash.new
    frame['txnr'] = 0
    frame['command'] = 'serverclose'
    begin
      self.frame_write(socket,frame)
      socket.close
    rescue ConnectionClosed
    end
  end

  def shutdown
    @server.close
  rescue Exception#@server might already be down
  end

  def ack(socket, txnr)
    frame = Hash.new
    frame['txnr'] = txnr
    frame['command'] = 'rsp'
    frame['message'] = '200 OK'
    self.frame_write(socket, frame)
  end

end

#This is only used by the tests; any problems here are not as important as elsewhere
class RelpClient < Relp

  def initialize(host,port,required_commands = [],buffer_size = 128,
                 retransmission_timeout=10)
    @logger = Cabin::Channel.get(LogStash)
    @logger.info? and @logger.info("Starting RELP client", :host => host, :port => port)
    @server = false
    @buffer = Hash.new

    @buffer_size = buffer_size
    @retransmission_timeout = retransmission_timeout

    #These are things that are part of the basic protocol, but only valid in one direction (rsp, close etc.)
    @basic_relp_commands = ['serverclose','rsp']#TODO: check for others

    #These are extra commands that we require, otherwise refuse the connection
    @required_relp_commands = required_commands

    @socket=TCPSocket.new(host,port)

    #This'll start the automatic frame numbering 
    @lasttxnr = 0

    offer=Hash.new
    offer['command'] = 'open'
    offer['message'] = 'relp_version=' + RelpVersion + "\n"
    offer['message'] += 'relp_software=' + RelpSoftware + "\n"
    offer['message'] += 'commands=' + @required_relp_commands.join(',')#TODO: add optional ones
    self.frame_write(@socket, offer)
    response_frame = self.frame_read(@socket)
    if response_frame['message'][0,3] != '200'
      raise RelpError,response_frame['message']
    end

    response=Hash[*response_frame['message'][7..-1].scan(/^(.*)=(.*)$/).flatten]
    if response['relp_version'].nil?
      #if no version specified, relp spec says we must close connection
      self.close()
      raise RelpError, 'No relp_version specified; offer: '
          + response_frame['message'][6..-1].scan(/^(.*)=(.*)$/).flatten

    #subtracting one array from the other checks to see if all elements in @required_relp_commands are present in the offer
    elsif ! (@required_relp_commands - response['commands'].split(',')).empty?
      #if it can't receive syslog it's useless to us; close the connection 
      self.close()
      raise InsufficientCommands, response['commands'] + ' offered, require '
          + @required_relp_commands.join(',')
    end
    #If we've got this far with no problems, we're good to go
    @logger.info? and @logger.info("Connection establish with server")

    #This thread deals with responses that come back
    reader = Thread.start do
      loop do
        f = self.frame_read(@socket)
        if f['command'] == 'rsp' && f['message'] == '200 OK'
          @buffer.delete(f['txnr'])
        elsif f['command'] == 'rsp' && f['message'][0,1] == '5'
          #TODO: What if we get an error for something we're already retransmitted due to timeout?
          new_txnr = self.frame_write(@socket, @buffer[f['txnr']])
          @buffer[new_txnr] = @buffer[f['txnr']]
          @buffer.delete(f['txnr'])
        elsif f['command'] == 'serverclose' || f['txnr'] == @close_txnr
          break
        else
          #Don't know what's going on if we get here, but it can't be good
          raise RelpError#TODO: raising errors like this makes no sense
        end
      end
    end

    #While this one deals with frames for which we get no reply
    Thread.start do
      old_buffer = Hash.new
      loop do
        #This returns old txnrs that are still present
        (@buffer.keys & old_buffer.keys).each do |txnr|
          new_txnr = self.frame_write(@socket, @buffer[txnr])
          @buffer[new_txnr] = @buffer[txnr]
          @buffer.delete(txnr)
        end
        old_buffer = @buffer
        sleep @retransmission_timeout
      end
    end
  end

  #TODO: have a way to get back unacked messages on close
  def close
    frame = Hash.new
    frame['command'] = 'close'
    @close_txnr=self.frame_write(@socket, frame)
    #TODO: ought to properly wait for a reply etc. The serverclose will make it work though
    sleep @retransmission_timeout
    @socket.close#TODO: shutdown?
    return @buffer
  end

  def syslog_write(logline)

    #If the buffer is already full, wait until a gap opens up
    sleep 0.1 until @buffer.length<@buffer_size

    frame = Hash.new
    frame['command'] = 'syslog'
    frame['message'] = logline

    txnr = self.frame_write(@socket, frame)
    @buffer[txnr] = frame
  end

  def nexttxnr
    @lasttxnr += 1
  end

end
