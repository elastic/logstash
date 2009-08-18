require 'rubygems'
require 'lib/net/common'
require 'json'

module LogStash; module Net
  class MessagePacket
    # 4 byte length
    # 4 byte checksum
    HEADERSIZE = 8 

    def self.each(data)
      done = false
      while !done
        have = data.length
        need = HEADERSIZE
        if have >= need
          need = data.unpack("N")[0] + HEADERSIZE
          if have >= need
            yield MessagePacket.new_from_encoded(data[0 .. need - 1])
          else
            done = true
          end
        else
          done = true
        end
        data[0 .. need - 1] = ""
      end
    end

    def self.new_from_encoded(string)
      len = string.unpack("N")[0]
      len, checksum, data = string.unpack("NNA#{len}")

      return MessagePacket.new(data, len=len, checksum=checksum)
    end

    def initialize(data, len=nil, checksum=nil)
      @content = data
      @length = (len or data.length)
      @checksum = (checksum or data.checksum)

      verify if length and checksum
    end

    def verify
      if (@content.checksum != @checksum or @content.length != @length)
        $stderr.puts "FAIL"
        raise MessageCorrupt.new(@checksum, @content)
      end
    end

    def encode
      return [@length, @checksum, @content].pack("NNA*")
    end

    public
    attr_reader :length
    attr_reader :content
    attr_reader :checksum

  end # class MessagePacket
end; end # module LogStash::Net
