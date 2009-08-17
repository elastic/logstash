module LogStash; module Net
  class MessageStream

    def initialize
      @data = Hash.new
      @data["version"] = PROTOCOL_VERSION
      @data["messages"] = Array.new
    end # def initialize

    def <<(message)
      @data["messages"] << message
    end # def <<

    def message_count
      return @data["messages"].length
    end

    def clear
      @data["messages"] = []
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
