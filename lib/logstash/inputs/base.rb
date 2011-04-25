require "logstash/namespace"
require "logstash/event"
require "logstash/logging"
require "logstash/config/mixin"

class LogStash::Inputs::Base
  include LogStash::Config::Mixin
  attr_accessor :logger

  config_name "input"

  # Label this input with a type.
  config :type, :validate => :string, :required => true

  # Set this to true to enable debugging on an input.
  config :debug, :validate => :boolean, :default => false

  # Add any number of arbitrary tags to your event.
  #
  # This can help with processing later.
  # TODO(sissel): do we really care what the value of this field is?
  #   can we just validate as an array of strings and call it done?
  config :tags, :validate => :array

  #config :tags, :validate => (lambda do |value|
    #re = /^[A-Za-z0-9_]+$/
    #value.each do |v|
      #if v !~ re
        #return [false, "Tag '#{v}' does not match #{re}"]
      #end # check 'v'
    #end # value.each 
    #return true
  #end) # config :tag

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDOUT)
    config_init(params)

    @tags ||= []
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def tag(newtag)
    @tags << newtag
  end # def tag
end # class LogStash::Inputs::Base
