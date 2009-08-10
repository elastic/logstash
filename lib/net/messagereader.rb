
module LogStash; module Net;
  READSIZE = 16384
  HEADERSIZE = 4

  class MessageReader
    def initialize(sock)
      @sock = sock
      @buffer = ""
    end

    def read
      @buffer += @sock.read_nonblock(READSIZE)
    end

    def each(&block)
      read
      have = @buffer.length
      if have < HEADERSIZE
        need = HEADERSIZE
      else
        need = @buffer[0 .. (HEADERSIZE - 1)].unpack("N")[0] + HEADERSIZE
      end

      if have > HEADERSIZE and have >= need
        data = @buffer[HEADERSIZE .. need - 1]
        @buffer[0 .. need - 1] = ""
        responses = MessageStream.decode(data) do |msg|
          yield msg
        end
      end
    end
  end # class MessageReader
end; end # module LogStash::Net
