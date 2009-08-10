require "json"

module BindToHash
  def hashbind(method, key)
    self.class_eval do
      #puts "hashbind #{method}"
      define_method(method) { BindToHash.hashpath_get(@data, key) }
      define_method("#{method}=") { |v| BindToHash.hashpath_set(@data, key, v) }
      #puts instance_method("#{method}=")
    end
  end

  def self.hashpath_get(data, key)
    elements = key.split("/")
    elements[0..-2].each do |k|
      next if k == ""
      data = data[k]
    end
    return data[elements[-1]]
  end

  def self.hashpath_set(data, key, value)
    elements = key.split("/")
    elements[0..-2].each do |k|
      next if k == ""
      data = data[k]
    end

    # TODO(sissel): Ruby's JSON barfs if you try to encode upper ascii characters
    # as it assumes all strings are unicode.
    (0 .. value.length - 1).each do |i|
      break if !value[i]
      if value[i] >= 128
        value[i] = ""
      end
    end

    data[elements[-1]] = value
  end
end # modules BindToHash

module LogStash
  PROTOCOL_VERSION = 1

  class MessageStream
    attr_reader :message_count

    def initialize
      @data = Hash.new
      @data["version"] = PROTOCOL_VERSION
      @data["messages"] = Array.new
      @message_count = 0
    end

    def <<(message)
      @data["messages"] << message
      @message_count += 1
    end

    def clear
      @data["messages"] = []
      @message_count = 0
    end
    
    def encode
      jsonstr = JSON::dump(@data)
      return jsonstr
    end

    def self.decode(string, &block)
      data = JSON::parse(string)
      ms = MessageStream.new
      if data["version"] != PROTOCOL_VERSION
        # throw some kind of error
      end

      data["messages"].each do |msgdata|
        msg = Message.new_from_data(msgdata)
        yield msg
      end
    end

  end

  class Message
    extend BindToHash
    attr_accessor :data

    # Message ID sequence number
    @@translators = Array.new
    @@idseq = 0

    # All message subclasses should register themselves here
    # This will allow Message.new_from_data to automatically return
    # the correct message instance.
    def self.translators
      return @@translators
    end

    def initialize
      @data = Hash.new
      data["id"] = @@idseq
      @@idseq += 1
    end

    def self.new_from_data(data)
      obj = nil
      @@translators.each do |klass|
        if klass.can_process?(data)
           obj = klass.new
        end
      end
      if !obj
        obj = Message.new
      end
      obj.data = data
      return obj
    end

    def to_json(*args)
      return @data.to_json(*args)
    end

    hashbind :id, "/id"

  protected
    attr :data
  end # class Message

  class RequestMessage < Message
    Message.translators << self
    def self.can_process?(data)
      return data.has_key?("request")
    end

    def initialize
      super
      @data["args"] = Hash.new
    end

    hashbind :name, "/request"
    hashbind :args, "/args"
  end # class RequestMessage

  class ResponseMessage < RequestMessage
    Message.translators << self
    def self.can_process?(data)
      return data.has_key?("response")
    end

    hashbind :name, "/response"
  end # class ResponseMessage
end
