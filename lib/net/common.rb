require 'zlib'

module LogStash; module Net;
  MAXMSGLEN = (1 << 20) # one megabyte message blocks

  class MessageCorrupt < StandardError
    attr_reader :expected_checksum
    attr_reader :data

    def initialize(checksum, data)
      @expected_checksum = checksum
      @data = data
      super("Corrupt message read. Expected checksum #{checksum}, got " + 
            "#{data.checksum}")
    end # def initialize
  end # class MessageReaderCorruptMessage

end; end # module LogStash::Net

# Add adler32 checksum from Zlib to String class
class String
  def adler32
    return Zlib.adler32(self)
  end # def checksum

  alias_method :checksum, :adler32
end # class String
