require "json"
# vim macro to replace 'hashbind :foo, "bar"' with two methods.
# yypkct:def lxf,sreturn @data[A]oenddef Jdt:xf,s(val)return @data[A] = valend

module BindToHash
  def hashbind(method, key)
    self.class_eval do
      define_method(method) { BindToHash.hashpath_get(@data, key) }
      define_method("#{method}=") { |v| BindToHash.hashpath_set(@data, key, v) }
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

    data[elements[-1]] = value
  end
end # modules BindToHash

module LogStash; module Net
  PROTOCOL_VERSION = 1

  class Message
    extend BindToHash
    attr_accessor :data

    # Message ID sequence number
    @@translators = Array.new

    # Message attributes
    def id
      return @data["id"]
    end

    def id=(val)
      return @data["id"] = val
    end

    # All message subclasses should register themselves here
    # This will allow Message.new_from_data to automatically return
    # the correct message instance.
    def self.translators
      return @@translators
    end

    def initialize
      @data = Hash.new
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

  protected
    attr :data
  end # class Message

  class RequestMessage < Message
    @@idseq = 0

    def initialize
      super
      generate_id!
    end

    Message.translators << self
    def self.can_process?(data)
      return data.has_key?("request")
    end

    def initialize
      super
      self.args = Hash.new
    end

    def generate_id!
      @data["id"] = @@idseq
      @@idseq += 1
    end

    # Message attributes
    def name
      return @data["request"]
    end

    def name=(val)
      return @data["request"] = val
    end

    def args
      return @data["args"]
    end

    def args=(val)
      return @data["args"] = val
    end
  end # class RequestMessage

  class ResponseMessage < RequestMessage
    Message.translators << self
    def self.can_process?(data)
      return data.has_key?("response")
    end

    # Message attributes
    def name
      return @data["response"]
    end

    def name=(val)
      return @data["response"] = val
    end

    # Report the success of the request this response is for.
    # Should be implemented by subclasses
    def success?
      raise NotImplementedError
    end
  end # class ResponseMessage
end; end # module LogStash::Net
