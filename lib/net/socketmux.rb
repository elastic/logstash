require 'rubygems'
require 'socket'
require 'time'
require 'lib/net/message'
require 'lib/net/messagereader'
require 'set'
require 'monitor'

# TODO(sissel): Need to implement 'read_until' callbacks.
# read_until(1000, bar) would call 'bar' when our buffer size is 1000 bytes

module LogStash; module Net
  MAXMSGLEN = (1 << 20)

  # We don't actually wait on acks, yet.
  ACKWAIT_MAX = 20

  # Acts as a client and a server.
  class MessageSocketMux
    def initialize
      @count = 0
      @start = Time.now.to_f

      @server = nil
      @receiver = nil

      # server_done is unused right now
      @server_done = false
      @receiver_done = false

      @readers = []
      @writers = []
      @sendbuffers = Hash.new { |h,k| h[k] = "" }
      @msgstreams = Hash.new do
        |h,k| h[k] = LogStash::Net::MessageStream.new
      end
      @msgstream_lock = Monitor.new
      @msgreaders = Hash.new do |h,k| 
        h[k] = LogStash::Net::MessageReader.new(k)
      end

      @ackwait = Set.new
      @done = false
    end

    # Set up a server and listen on a port
    def listen(addr="0.0.0.0", port=0)
      @server = TCPServer.new(addr, port)
      @readers << @server
    end

    # Connect to a remote server
    def connect(addr="0.0.0.0", port=0)
      @receiver = TCPSocket.new(addr, port)
      add_socket(@receiver)
    end

    def add_socket(sock)
      @readers << sock
      @writers << sock
    end

    def sendmsg(msg, sock=nil)
      if msg == nil
        raise "msg is nil"
      end

      sock = (sock or @receiver)
      if !@writers.include?(sock)
        @writers << sock
      end
      @msgstreams[sock] << msg
      @ackwait << msg.id
    end

    def run
      while !@done
        s_in, s_out, s_err = IO.select(@readers, @writers, nil, nil)

        if s_in
          handle_in(s_in)
        end

        if s_out
          handle_out(s_out)
        end
      end
    end

    def close
      if @receiver
        @receiver_done = true
        # Don't close our writer yet. Wait until our outbound queue is empty.
      end

      if @serer
        @server_done = true

        # Stop accepting new connections.
        @server.close_read
        @readers.delete(@server)
      end
    end

    def handle_in(socks)
      socks.each do |sock|
        if sock == @server
          server_handle(sock)
        elsif sock == @receiver
          client_handle(sock)

          # only close the writer if we are done and have no messages left to send
          if @msgstreams[sock].message_count == 0 and @receiver_done
            sock.close_write rescue IOError
          end
        else
          client_handle(sock)
        end
      end
    end

    def handle_out(socks)
      socks.each do |sock|
        ms = @msgstreams[sock]
        if ms.message_count > 0
          begin
            ms.sendto(sock)
            @writers.delete(sock)
          rescue Errno::ECONNRESET, Errno::EPIPE
            $stderr.puts "write error, dropping connection"
            remove(sock)
          end
        end
      end
    end

    def server_handle(sock)
      client = sock.accept_nonblock
      add_socket(client)
    end
    
    def client_handle(sock)
      begin
        @msgreaders[sock].each do |msg|
          message_handle(msg) do |reply|
            # Send a reply for the msg.
            sendmsg(reply, sock)
          end
        end
      rescue EOFError, IOError, Errno::ECONNRESET
        remove(sock)
      end
    end

    def message_handle(msg)
      if msg.is_a?(ResponseMessage) and @ackwait.include?(msg.id)
        @ackwait -= [msg.id]
        #puts "ackwait #{@ackwait.length}"
      end

      msgtype = msg.class.name.split(":")[-1]
      handler = "#{msgtype}Handler"
      if self.respond_to?(handler)
        reply = self.send(handler, msg)
        yield reply if reply != nil
      else
        $stderr.puts "No handler for message class '#{msg.class.name}'"
      end
    end
      
    def remove(sock)
      @writers.delete(sock)
      @readers.delete(sock)
      @msgreaders.delete(sock)
      @sendbuffers.delete(sock)
      @msgstreams.delete(sock)

      begin
        sock.close
      rescue IOError
        # ignore 'close' errors
      end

      @done = (@writers.length == 0 and @readers.length == 0)
    end
  end # class MessageSocketMux
end; end # module LogStash::Net
