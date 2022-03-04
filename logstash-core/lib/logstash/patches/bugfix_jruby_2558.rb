# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/environment"

if LogStash::Environment.windows?
  require "socket"
  module JRubyBug2558SocketPeerAddrBugFix
    def peeraddr(*args)
      orig_peeraddr(*args).map do |v|
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

if LogStash::Environment.windows?
  # make sure all strings pulled out of ENV are UTF8
  class <<ENV
    alias_method :orig_getter, :[]
    def [](key)
      case value = orig_getter(key)
      when String
        # dup is necessary since force_encoding is destructive
        value.dup.force_encoding(Encoding::UTF_8)
      else
        value
      end
    end
  end
end
