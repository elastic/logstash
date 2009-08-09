require 'rubygems'
require 'socket'
require 'time'
require 'lib/net/message'
require 'lib/net/messages/indexevent'

module Logstash
  MAXMSGLEN = (1 << 20)

  class MessageServer
    def initialize
      @serversock = TCPServer.new(4044)
      @socks = [@serversock]
      @buffers = Hash.new { |h,k| h[k] = "" }
    end

    def run
      while true
        s_in, s_out, s_err = IO.select(@socks, nil, @socks, 5)
        if s_in
          s_in.each do |sock|
            handle(sock)
          end
        end
      end
    end

    def handle(sock)
      if sock == @serversock
        return server_handle(sock)
      else
        return client_handle(sock)
      end

    end

    def server_handle(sock)
      # Greedily accept.
      done = false
      while !done
        begin
          client = sock.accept_nonblock
          @socks << client
          puts "New client: #{client}"
        rescue Errno::EAGAIN
          # Nothing left to accept
          done = true
        end
      end
    end

    def client_handle(sock)
      begin
        length = sock.sysread(4).unpack("N")[0]
        if length == nil or length > MAXMSGLEN
          $stderr.puts "invalid length (#{length}), dropping client."
          remove(sock)
          return
        end

        data = sock.read(length)
      rescue EOFError
        remove(sock)
        return
      end
      
      MessageStream.decode(data) do |msg|
        puts msg.inspect
      end
    end

    def remove(sock)
      @socks.delete(sock)
      sock.close
    end
  end # class MessageServer
end
