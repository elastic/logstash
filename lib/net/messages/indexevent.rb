require "mqrpc"

module LogStash; module Net; module Messages
  class IndexEventRequest < MQRPC::RequestMessage
    argument :log_type
    argument :log_data
    argument :metadata

    def initialize
      super
      self.metadata = Hash.new
    end
  end # class IndexEventRequest

  class IndexEventResponse < MQRPC::ResponseMessage
    argument :code
    argument :error

    def success?
      return self.code == 0
    end
  end # class IndexEventResponse
end; end; end # module LogStash::Net::Messages
