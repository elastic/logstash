
require "lib/net/message"

module LogStash
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

    hashbind :code, "/args/code"
    hashbind :error, "/args/error"
  end # class IndexEventResponse
end
