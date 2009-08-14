require 'lib/net/common'
require 'lib/net/message'
require 'lib/net/messagereader'
require 'set'
require 'socket'
require 'thread'
require 'time'

module LogStash; module Net
  class MessageSocketMux
    def initialize
      @writelock = Mutex.new
      @server = nil
      @receiver = nil

      # server_done is unused right now
      @server_done = false
      @receiver_done = false

      # Socket list for readers and writers
      @readers = []
      @writers = []

      @msgoutstreams = Hash.new do
        |h,k| h[k] = LogStash::Net::MessageStream.new
      end
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

    # Send a message. This method queues the message in the outbound
    # message queue. To actually make the message get sent on the wire
    # you need to call MessageSocketMux#sendrecv or MessageSocketMux#run
    #
    # If you are implementing a client, you can omit the 'sock' argument
    # because it will automatically send to the server you connected to.
    # If a socket is given, send to that specific socket. 
    def sendmsg(msg, sock=nil)
      @writelock.synchronize do
        _sendmsg(msg, sock)
      end
    end

    # Run indefinitely.
    # Ending conditions are when there are no sockets left open.
    # If you want to terminate the server (#listen or #connect) then
    # call MessageSocketMux#close
    def run
      while !@done
        sendrecv(nil)
      end
    end

    # Wait for network data (input and output) for the given timeout
    # If timeout is nil, we will wait until there is data.
    # If timeout is a positive number, we will wait that number of seconds
    #   or until there is data - whichever is first.
    # If timeout is zero, we will not wait at all for data.
    #
    # Returns true if there was network data handled, false otherwise.
    def sendrecv(timeout=nil)
      s_in, s_out, s_err = IO.select(@readers, @writers, nil, timeout)
      handle_in(s_in) if s_in
      handle_out(s_out) if s_out

      # Return true if we got data at all.
      return (s_in != nil or s_out != nil)
    end

    def close
      if @receiver
        @receiver_done = true
        # Don't close our writer yet. Wait until our outbound queue is empty.
      end

      if @server
        @server_done = true
        # Stop accepting new connections.
        remove_reader(@server)
      end
    end

    private
    def add_socket(sock)
      @readers << sock
      @writers << sock
    end

    private
    def _sendmsg(msg, sock=nil)
      if msg == nil
        raise "msg is nil"
      end

      # Handle if 'msg' is actually an array of messages
      if msg.is_a?(Array)
        msg.each do |m|
          _sendmsg(m, sock)
        end
        return
      end

      if msg.is_a?(RequestMessage) and msg.id == nil
        msg.generate_id!
      end

      sock = (sock or @receiver)
      if !@writers.include?(sock)
        @writers << sock
      end
      @msgoutstreams[sock] << msg
      @ackwait << msg.id
    end # def _sendmsg

    private
    def remove_writer(sock)
      puts "remove writer: #{caller[0]}"
      @writers.delete(sock)
      @msgoutstreams.delete(sock)
      sock.close_write() rescue nil   # Ignore close errors
      check_done
    end # def remove_writer

    private
    def remove_reader(sock)
      puts "remove reader: #{caller[0]}"
      @readers.delete(sock)
      @msgreaders.delete(sock)
      sock.close_read() rescue nil   # Ignore close errors
      check_done
    end # def remove_reader

    private
    def remove(sock)
      remove_writer(sock)
      remove_reader(sock)
    end; # def remove

    private
    def check_done
      @done = (@writers.length == 0 and @readers.length == 0)
    end # def check_done

    private
    def handle_in(socks)
      socks.each do |sock|
        if sock == @server
          server_handle(sock)
        else
          client_handle(sock)
        end
      end 
    end # def handle_in

    private
    def handle_out(socks)
      # Lock early in the event we have to handle lots of sockets or messages
      # Locking too much causes slowdowns.
      @writelock.synchronize do
        socks.each do |sock|
          ms = @msgoutstreams[sock]
          if ms.message_count == 0
            if @receiver_done and sock == @receiver
              remove_writer(sock)
            end
          else
            # There are messages to send...
            encoded = ms.encode
            data = [encoded.length, encoded].pack("NA*")
            len = data.length
            begin
              sock.write(data)
            rescue Errno::ECONNRESET, Errno::EPIPE => e
              $stderr.puts "write error, dropping connection (#{e})"
              remove(sock)
            end
            ms.clear
          end # else / ms.message_count == 0
        end # socks.each
      end # @writelock.synchronize
    end # def handle_out

    private
    def server_handle(sock)
      client = sock.accept_nonblock
      add_socket(client)
    end # def server_handle

    private
    def client_handle(sock)
      begin
        @msgreaders[sock].each do |msg|
          message_handle(msg) do |response|
            _sendmsg(response, sock)
          end
        end
      rescue EOFError, IOError, Errno::ECONNRESET => e
        remove_reader(sock)
      end
    end # def client_handle

    private
    def message_handle(msg)
      if msg.is_a?(ResponseMessage) and @ackwait.include?(msg.id)
        @ackwait.delete(msg.id)
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
    end # def message_handle
  end # class MessageSocketMux
end; end # module LogStash::Net
