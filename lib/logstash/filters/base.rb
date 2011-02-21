require "logstash/namespace"
require "logstash/logging"
require "logstash/config/mixin"

class LogStash::Filters::Base
  include LogStash::Config::Mixin

  attr_accessor :logger

  config_name "filter"
  config :type => :string
  config :add_tag => nil
  config :add_field => nil

  public
  def initialize(params)
    @logger = LogStash::Logger.new(STDERR)
    config_init(params)
  end # def initialize

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def filter(event)
    raise "#{self.class}#filter must be overidden"
  end # def filter

  public
  def add_config(type, typeconfig)
    if @config.include?(type)
      @config[type].merge!(typeconfig)
    else
      @config[type] = typeconfig
    end
  end # def add_config

  # a filter instance should call filter_matches from filter if the event
  # matches the filter's conditions (right type, etc)
  private
  def filter_matched(event)
    if @add_tag
      @add_tag.each { |tag| event.tags << tag }
    end
    if @add_field
      if @add_field.length % 2 != 0
        @logger.warn("filter #{self.class}: add_field must be an even amount of fields [key1, val1, key2, val2, ...]")
      else
        combos = @add_field.length / 2
        0.upto(combos - 1) do |i|
          field, value = @add_field[2*i], @add_field[2*i+1]
          event[field] ||= []
          event[field] << value
        end # 0.upto(combos)
      end # if @add_field.length % 2
    end # if @add_field
  end # def filter_matched
end # class LogStash::Filters::Base
