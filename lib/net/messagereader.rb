
module LogStash; module Net;
  READSIZE = 16384
  HEADERSIZE = 4

  class MessageReader
    def initialize(sock)
      @sock = sock
      @buffer = ""
    end

    def read
      begin
        (1..5).each do
          @buffer += @sock.read_nonblock(READSIZE)
        end
      rescue Errno::EAGAIN
        # ignore
      end
    end

    def each(&block)
      begin
        read
      rescue EOFError => e
        # Only reraise EOFError if we have nothing left in the buffer.
        # If we have buffer left, it's not really an EOF.
        if @buffer.length == 0
          raise e
        end
      end

      done = false
      x = 0
      # Since we read 16K blocks, we may be given more than one message set
      # so process until our buffer is exhausted.
      while !done
        have = @buffer.length
        if have < HEADERSIZE
          need = HEADERSIZE
        else
          need = @buffer[0 .. (HEADERSIZE - 1)].unpack("N")[0] + HEADERSIZE
        end

        if have > HEADERSIZE and have >= need
          x += 1
          data = @buffer[HEADERSIZE .. need - 1]
          @buffer[0 .. need - 1] = ""
          responses = MessageStream.decode(data) do |msg|
            yield msg
          end
        else
          # Not enough buffer left to make up a full message,
          # wait until next round.
          done = true
        end
      end #loop
    end
  end # class MessageReader
end; end # module LogStash::Net
