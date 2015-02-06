require "logstash/environment"

if LogStash::Environment.windows? && LogStash::Environment.jruby? then
  require "socket"
  module JRubyBug2558SocketPeerAddrBugFix
    def peeraddr
      orig_peeraddr.map do |v|
        case v
        when String
          v.force_encoding(Encoding::UTF_8)
        else
          v
        end
      end
    end
  end

  class << Socket
    # Bugfix for jruby #2558
    alias_method :orig_gethostname, :gethostname
    def gethostname
      return orig_gethostname.force_encoding(Encoding::UTF_8)
    end
  end

  class TCPSocket
    alias_method :orig_peeraddr, :peeraddr
    include JRubyBug2558SocketPeerAddrBugFix
  end
  class UDPSocket
    alias_method :orig_peeraddr, :peeraddr
    include JRubyBug2558SocketPeerAddrBugFix
  end
end
