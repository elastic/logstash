require 'json'
require 'set'
# vim macro to replace 'hashbind :foo, "bar"' with two methods.
# yypkct:def lxf,sreturn @data[A]oenddef Jdt:xf,s(val)return @data[A] = valend

module BindToHash
  def hashbind(method, key)
    hashpath = BindToHash.genhashpath(key)
    self.class_eval %(
      def #{method}
        return #{hashpath}
      end
      def #{method}=(val)
        #{hashpath} = val
      end
    )
  end

  def self.genhashpath(key)
    path = key.split("/").select { |x| x.length > 0 }.map { |x| "[#{x.inspect}]" }
    return "@data#{path.join("")}"
  end
end # modules BindToHash

module LogStash; module Net
  PROTOCOL_VERSION = 1

  class Message
    extend BindToHash
    attr_accessor :data

    # list of class instances that can identify messages
    @@translators = Hash.new

    # Message attributes
    hashbind :id, "id"
    hashbind :replyto, "reply-to"
    hashbind :timestamp, "timestamp"

    def age
      return Time.now.to_f - timestamp
    end

    # All message subclasses should register themselves here
    # This will allow Message.new_from_data to automatically return
    # the correct message instance.
    def self.translators
      return @@translators
    end

    def self.register
      name = self.name.split(":")[-1]
      self.class_eval %(
        def _name
          return "#{name}"
        end
      )
      @@translators[name] = self
    end

    def initialize
      @data = Hash.new
    end

    def self.new_from_data(data)
      obj = nil
      #@@translators.each do |translator|
      name = data["type"]
      if @@translators.has_key?(name)
        obj = @@translators[name].new
      else
        $stderr.puts "No translator found for #{name} / #{data.inspect}"
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
      self.args = Hash.new
      self.name = self._name
      generate_id!
    end

    def generate_id!
      @data["id"] = @@idseq
      @@idseq += 1
    end

    # Message attributes
    def name
      return @data["type"]
    end

    def name=(val)
      return @data["type"] = val
    end

    def args
      return @data["args"]
    end

    def args=(val)
      return @data["args"] = val
    end
  end # class RequestMessage

  class ResponseMessage < RequestMessage
    #Message.translators << self

    # Report the success of the request this response is for.
    # Should be implemented by subclasses
    def success?
      raise NotImplementedError
    end
  end # class ResponseMessage
end; end # module LogStash::Net
