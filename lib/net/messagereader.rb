require 'lib/net/common'

module LogStash; module Net;
  READSIZE = 16384
  HEADERSIZE = 8

  class MessageReaderCorruptMessage < StandardError
    attr_reader :expected_checksum
    attr_reader :data

    def initialize(checksum, data)
      @expected_checksum = checksum
      @data = data
      super("Corrupt message read. Expected checksum #{checksum}, got " + 
            "#{data.checksum} / #{data.inspect}")
    end # def initialize
  end # class MessageReaderCorruptMessage

  # This class will yield Message objects from a socket.
  class MessageReader
    def initialize(sock)
      @sock = sock
      @buffer = ""
    end # def initialize

    def each(&block)
      try_read

      # Since we read 16K blocks, we may be given more than one message set
      # so process until our buffer is exhausted.
      while ready?
        need = next_length
        length, checksum, data = @buffer.unpack("NNA#{need - HEADERSIZE}")
        @buffer[0 .. need - 1] = ""
        responses = MessageStream.decode(data) do |msg|
          yield msg
        end
      end #loop
    end # def each

    # Get a single message, if it exists
    def get
      # Is this safe?
      each do |msg|
        return msg
      end

      # No message if we get here.
      return nil
    end

    private
    def try_read
      begin
        read
      rescue EOFError => e
        # Only reraise EOFError if we have nothing left in the buffer.
        # If we have buffer left, it's not really an EOF.
        if @buffer.length == 0
          raise e
        end
      end
    end

    private
    # tries to populate our buffer from our socket
    def read
      # try to be greedy if we're told it's OK to read.
      begin
        1.upto(5).each do
          @buffer += @sock.read_nonblock(READSIZE)
        end
      rescue Errno::EAGAIN
        # break early if we get EAGAIN (aka, there's no data to read)
      end
    end # def read

    private
    # returns true if we have enough data in the buffer to make up
    # a full message.
    def ready?
      have = @buffer.length
      need = HEADERSIZE
      if have > HEADERSIZE
        need = next_length

        if have >= need
          length, checksum, data = @buffer.unpack("NNA#{need - HEADERSIZE}")
          if data.checksum != checksum
            puts @buffer.inspect[0..200]
            raise MessageReaderCorruptMessage.new(checksum, data)
          end
          return true
        end
      end

      return false
    end

    private
    def next_length
      @buffer.unpack("N")[0] + HEADERSIZE
    end # def next_length

  end # class MessageReader
end; end # module LogStash::Net
