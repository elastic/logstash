
require "lib/net/message"

module LogStash; module Net; module Messages
  class PingRequest < RequestMessage
    Message.translators << self
    def self.can_process?(data)
      return (super(data) and data["request"] == "Ping")
    end

    def initialize
      super
      self.name = "Ping"
      self.pingdata = Time.now.to_f
    end

    # Message attributes
    hashbind :pingdata, "/args/pingdata"
  end # class PingRequest

  class PingResponse < ResponseMessage
    Message.translators << self
    def self.can_process?(data)
      return (super(data) and data["response"] == "Ping")
    end

    def initialize
      super
      self.name = "Ping"
    end

    # Message attributes
    hashbind :pingdata, "/args/pingdata"
  end # class PingResponse
end; end; end # module LogStash::Net::Messages
