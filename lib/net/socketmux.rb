require 'rubygems'
require 'socket'
require 'time'
require 'lib/net/message'
require 'lib/net/messages/indexevent'

# TODO(sissel): Need to implement 'read_until' callbacks.
# read_until(1000, bar) would call 'bar' when our buffer size is 1000 bytes

module LogStash; module Net
  MAXMSGLEN = (1 << 20)

  # Acts as a client and a server.
  class MessageSocketMux
    def initialize
      @count = 0
      @start = Time.now.to_f

      @listener = nil
      @socks = []
      @recvbuffers = Hash.new { |h,k| h[k] = "" }
      @sendbuffers = Hash.new { |h,k| h[k] = "" }
    end

    def listen(addr="0.0.0.0", port=0)
      @listener = TCPServer.new(addr, port)
      @socks << @listener
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
      ms = LogStash::Net::MessageStream.new
      ms << msg
      data = ms.encode
      #puts "Sending msg #{msg.class}: #{data.length}"
      @sendbuffers[sock] += [data.length, data].pack("NA*")
    end

    def run
      while true
        s_in, s_out, s_err = IO.select(@socks, @socks, @socks, 5)
        if s_in
          s_in.each do |sock|
            handle(sock)
          end
        end

        if s_out
          s_out.each do |sock|
            if @sendbuffers[sock].length > 0
              #puts "Sending #{@sendbuffers[sock].length} bytes to #{sock}"
              begin
                sock.write(@sendbuffers[sock])
              rescue Errno::ECONNRESET
                remove(sock)
              end
              @sendbuffers[sock] = ""
            end
          end
        end
      end
    end

    def handle(sock)
      if sock == @listener
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
        if have < 4
          need = 4
        else
          need = @recvbuffers[sock][0..3].unpack("N")[0] + 4
        end

        # Read if buffer is not full enough.
        if have < need
          @recvbuffers[sock] += sock.read_nonblock(16384)
        end

        if have > 4 && have >= need
          reply = client_streamready(@recvbuffers[sock][4..(need - 1)])
          @recvbuffers[sock] = (@recvbuffers[sock][need .. -1] or "")
          #puts "Sending #{reply.class}"
          #sock.write(reply)
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
      begin
        #sock.close
      rescue IOError
        # ignore 'close' errors
      end
    end
  end # class MessageServer
end; end # module LogStash::Net
