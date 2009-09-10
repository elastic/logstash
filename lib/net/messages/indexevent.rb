
require "lib/net/message"

module LogStash; module Net; module Messages
  class IndexEventRequest < RequestMessage
    register

    def initialize
      super
      self.metadata = Hash.new
    end

    hashbind :log_type, "/args/type"
    hashbind :log_data, "/args/message"
    hashbind :metadata, "/args/metadata"
  end # class IndexEventRequest

  class IndexEventResponse < ResponseMessage
    register

    # Message attributes
    hashbind :code, "/args/code"
    hashbind :error, "/args/error"

    def success?
      return self.code == 0
    end
  end # class IndexEventResponse
end; end; end # module LogStash::Net::Messages
