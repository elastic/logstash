require 'rubygems'
require 'socket'
require 'time'
require 'lib/net/message'

# TODO(sissel): Need to implement 'read_until' callbacks.
# read_until(1000, bar) would call 'bar' when our buffer size is 1000 bytes

module LogStash; module Net
  MAXMSGLEN = (1 << 20)
  HEADERSIZE = 4

  # Acts as a client and a server.
  class MessageSocketMux
    def initialize
      @count = 0
      @start = Time.now.to_f

      @server = nil
      @socks = []
      @recvbuffers = Hash.new { |h,k| h[k] = "" }
      @sendbuffers = Hash.new { |h,k| h[k] = "" }
      @msgstreams = Hash.new { |h,k| h[k] = LogStash::Net::MessageStream.new }
      @outsocks = []
      @done = false
    end

    def listen(addr="0.0.0.0", port=0)
      @server = TCPServer.new(addr, port)
      @socks << @server
    end

    def connect(addr="0.0.0.0", port=0)
      @receiver = TCPSocket.new(addr, port)
      @socks << @receiver
    end

    def sendmsg(msg, sock=nil)
      if msg == nil
        raise "msg is nil"
      end
      sock = (sock or @receiver)
      if !@outsocks.include?(sock)
        @outsocks << sock
      end
      @msgstreams[sock] << msg
      #data = ms.encode
      #puts "Sending msg #{msg.class}: #{data.length}"
      #@sendbuffers[sock] += [data.length, data].pack("NA*")
    end

    def run
      while !@done
        #puts "socks: #{@socks.length}"
        #puts "outsocks: #{@outsocks.length}"
        s_in, s_out, s_err = IO.select(@socks, @outsocks, [], nil)
        if s_in
          #puts s_in.length
          s_in.each do |sock|
            handle(sock)
          end
        end

        if s_out
          #puts s_out.length
          s_out.each do |sock|
            ms = @msgstreams[sock]
            if ms.message_count > 0
              begin
                ms.sendto(sock)
                @outsocks.delete(sock)
              rescue Errno::ECONNRESET, Errno::EPIPE
                remove(sock)
              end
            end
          end
        end
      end
    end

    def close
      # nothing for now
      if @receiver
        @receiver.close_write
      end
      if @serer
        @server.close_read
      end
    end

    def handle(sock)
      if sock == @server
        server_handle(sock)
      else
        client_handle(sock)
      end
    end

    def server_handle(sock)
      client = sock.accept_nonblock
      @socks << client
      #puts "New client: #{client}"
    end
    
    # TODO(sissel): extrapolate the 'read chunks until we get a full message set'
    # code into it's own class.
    def client_handle(sock)
      begin
        have = @recvbuffers[sock].length
        # need at least 4 bytes (the length)
        if have < HEADERSIZE
          need = HEADERSIZE
        else
          need = @recvbuffers[sock][0..3].unpack("N")[0] + HEADERSIZE
        end

        # Read if buffer is not full enough.
        if have < need
          begin
            data = sock.read_nonblock(16384)
            @recvbuffers[sock] += data
            have += data.length
            if need == HEADERSIZE
              need = @recvbuffers[sock][0..3].unpack("N")[0] + HEADERSIZE
            end
          rescue Errno::EAGAIN
            return
          end
        end

        if (have > HEADERSIZE and have >= need)
          reply = client_streamready(@recvbuffers[sock][HEADERSIZE..(need - 1)])
          @recvbuffers[sock] = (@recvbuffers[sock][need .. -1] or "")

          reply.each do |msg|
            next if msg == nil
            sendmsg(msg, sock)
          end
            
        end
      rescue EOFError, IOError
        remove(sock)
      end
    end
      
    def client_streamready(data)
      #puts "ready: #{data.length}"
      #puts data.inspect
      responses = MessageStream.decode(data) do |msg|
        @count += 1
        msgtype = msg.class.name.split(":")[-1]
        handler = "#{msgtype}Handler"
        if self.respond_to?(handler)
          self.send(handler, msg)
        else
          $stderr.puts "No handler for message class '#{msg.class.name}'"
        end
      end

      #replystream = MessageStream.new
      #responses.each { |r| replystream << r }
      return responses
    end

    def remove(sock)
      #puts "Removing #{sock}"
      @socks.delete(sock)
      @recvbuffers.delete(sock)
      @sendbuffers.delete(sock)
      @msgstreams.delete(sock)
      @outsocks.delete(sock)
      begin
        sock.close
      rescue IOError
        # ignore 'close' errors
      end

      if sock == @receiver and @server == nil
        @done = true
      end

      if sock == @server and @receiver == nil
        @done = true
      end
    end
  end # class MessageSocketMux
end; end # module LogStash::Net
