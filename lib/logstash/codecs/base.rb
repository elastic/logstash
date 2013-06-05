require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"
require "extlib"

# This is the base class for logstash codecs.
module LogStash::Codecs
  public
  def self.for(codec)
    return codec unless codec.is_a? String

    #TODO: codec paths or just use plugin paths
    plugin = File.join('logstash', 'codecs', codec) + ".rb"
    #@logger.info "Loading codec", :codec => plugin
    require plugin
    klass_name = codec.camel_case
    if LogStash::Codecs.const_defined?(klass_name)
      return LogStash::Codecs.const_get(klass_name)
    end
    nil
  end

  class Base < LogStash::Plugin
    include LogStash::Config::Mixin
    config_name "codec"

    attr_reader :on_event
    attr_accessor :charset

    public
    def initialize(params={})
      super
      config_init(params)

    end

    public
    def decode(data)
      raise "#{self.class}#decode must be overidden"
    end # def decode

    alias_method :<<, :decode

    public
    def encode(data)
      raise "#{self.class}#encode must be overidden"
    end # def encode

    public 
    def teardown; end;

    public
    def on_event(&block)
      @on_event = block
    end

  end # class LogStash::Codecs::Base
end