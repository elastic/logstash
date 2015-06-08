# encoding: utf-8
require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"

# This is the base class for logstash codecs.
module LogStash::Codecs
  class Base < LogStash::Plugin
    include LogStash::Config::Mixin
    config_name "codec"

    def initialize(params={})
      super
      config_init(params)
      register if respond_to?(:register)
    end

    def decode(data)
      raise "#{self.class}#decode must be overidden"
    end # def decode

    alias_method :<<, :decode

    def encode(event)
      raise "#{self.class}#encode must be overidden"
    end # def encode

    def teardown
      # override if needed
    end

    # @param block [Proc(event, data)] the callback proc passing the original event and the encoded event
    def on_event(&block)
      @on_event = block
    end

    def flush(&block)
      # override if needed
    end

    def clone
      return self.class.new(params)
    end
  end
end
