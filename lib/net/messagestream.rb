module LogStash; module Net
  class MessageStream
    attr_reader :message_count

    def initialize
      @data = Hash.new
      @data["version"] = PROTOCOL_VERSION
      @data["messages"] = Array.new
      @message_count = 0
    end # def initialize

    def <<(message)
      @data["messages"] << message
      @message_count += 1
    end # def <<

    def clear
      @data["messages"] = []
      @message_count = 0
    end # def clear

    def encode
      jsonstr = JSON::dump(@data)
      return jsonstr
    end # def encode

    def sendto(sock)
      data = self.encode
      #puts "Writing #{data.length} bytes to #{sock}"
      #puts data.inspect
      sock.write([data.length, data].pack("NA*"))
      self.clear
    end # def sendto

    def self.decode(string, &block)
      data = JSON::parse(string)
      ms = MessageStream.new
      if data["version"] != PROTOCOL_VERSION
        # throw some kind of error
      end

      responses = []
      data["messages"].each do |msgdata|
        msg = Message.new_from_data(msgdata)
        responses << (yield msg)
      end
      return responses
    end # def self.decode
  end # class MessageStream
end; end # module LogStash::Net
