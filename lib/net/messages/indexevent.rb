
require "lib/net/message"

module LogStash; module Net; module Messages
  class IndexEventRequest < RequestMessage
    Message.translators << self
    def self.can_process?(data)
      return (super(data) and data["request"] == "IndexEvent")
    end

    def initialize
      super
      self.name = "IndexEvent"
      self.metadata = Hash.new
    end

    # Message attributes
    def log_type
      return @data["args"]["type"]
    end

    def log_type=(val)
      return @data["args"]["type"] = val
    end
    def log_data
      return @data["args"]["message"]
    end

    def log_data=(val)
      return @data["args"]["message"] = val
    end

    def metadata
      return @data["args"]["metadata"]
    end

    def metadata=(val)
      return @data["args"]["metadata"] = val
    end
  end # class IndexEventRequest

  class IndexEventResponse < ResponseMessage
    Message.translators << self
    def self.can_process?(data)
      return (super(data) and data["response"] == "IndexEvent")
    end

    def initialize
      super
      self.name = "IndexEvent"
    end

    # Message attributes
    hashbind :code, "/args/code"
    hashbind :error, "/args/error"

    def success?
      return self.code == 0
    end
  end # class IndexEventResponse
end; end; end # module LogStash::Net::Messages
