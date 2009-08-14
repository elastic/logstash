
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
    hashbind :log_type, "/args/type"
    hashbind :log_data, "/args/message"
    hashbind :metadata, "/args/metadata"
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
