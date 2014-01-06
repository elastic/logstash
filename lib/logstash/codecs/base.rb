# encoding: utf-8
require "logstash/namespace"
require "logstash/event"
require "logstash/plugin"
require "logstash/logging"

# This is the base class for logstash codecs.
module LogStash::Codecs; class Base < LogStash::Plugin
  include LogStash::Config::Mixin
  config_name "codec"

  def initialize(params={})
    super
    config_init(params)
    register if respond_to?(:register)
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

  public
  def flush(&block)
    # does nothing by default.
    # if your codec needs a flush method (like you are spooling things)
    # you must implement this.
  end

  public
  def clone
    return self.class.new(params)
  end
end; end # class LogStash::Codecs::Base
