require 'zlib'

module LogStash; module Net;
  MAXMSGLEN = (1 << 20) # one megabyte message blocks

end; end # module LogStash::Net

# Add adler32 checksum from Zlib to String class
class String
  def adler32
    return Zlib.adler32(self)
  end # def checksum

  alias_method :checksum, :adler32
end # class String
