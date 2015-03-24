# encoding: utf-8
require "cgi"
require "logstash/event"
require "logstash/logging"
require "logstash/plugin"
require "logstash/namespace"
require "logstash/config/mixin"
require "uri"

class LogStash::Outputs::Base < LogStash::Plugin
  include LogStash::Config::Mixin

  config_name "output"

  # The type to act on. If a type is given, then this output will only
  # act on messages with the same type. See any input plugin's `type`
  # attribute for more.
  # Optional.
  config :type, :validate => :string, :default => "", :deprecated => "You can achieve this same behavior with the new conditionals, like: `if [type] == \"sometype\" { %PLUGIN% { ... } }`."

  # Only handle events with all of these tags.
  # Optional.
  config :tags, :validate => :array, :default => [], :deprecated => "You can achieve similar behavior with the new conditionals, like: `if \"sometag\" in [tags] { %PLUGIN% { ... } }`"

  # Only handle events without any of these tags.
  # Optional.
  config :exclude_tags, :validate => :array, :default => [], :deprecated => "You can achieve similar behavior with the new conditionals, like: `if !(\"sometag\" in [tags]) { %PLUGIN% { ... } }`"

  # The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output, without needing a separate filter in your Logstash pipeline.
  config :codec, :validate => :codec, :default => "plain"

  # The number of workers to use for this output.
  # Note that this setting may not be useful for all outputs.
  config :workers, :validate => :number, :default => 1

  attr_reader :worker_plugins

  public
  def workers_not_supported(message=nil)
    return if @workers == 1
    if message
      @logger.warn(I18n.t("logstash.pipeline.output-worker-unsupported-with-message", :plugin => self.class.config_name, :worker_count => @workers, :message => message))
    else
      @logger.warn(I18n.t("logstash.pipeline.output-worker-unsupported", :plugin => self.class.config_name, :worker_count => @workers))
    end
    @workers = 1
  end

  public
  def initialize(params={})
    super
    config_init(params)
  end

  public
  def register
    raise "#{self.class}#register must be overidden"
  end # def register

  public
  def receive(event)
    raise "#{self.class}#receive must be overidden"
  end # def receive

  public
  def worker_setup
    if @workers == 1
      @worker_plugins = [self]
    else
      define_singleton_method(:handle, method(:handle_worker))
      @worker_queue = SizedQueue.new(20)
      @worker_plugins = @workers.times.map { self.class.new(@original_params.merge("workers" => 1)) }
      @worker_plugins.map.with_index do |plugin, i|
        Thread.new(original_params, @worker_queue) do |params, queue|
          LogStash::Util::set_thread_name(">#{self.class.config_name}.#{i}")
          plugin.register
          while true
            event = queue.pop
            plugin.handle(event)
          end
        end
      end
    end
  end

  public
  def handle(event)
    receive(event)
  end # def handle

  def handle_worker(event)
    @worker_queue.push(event)
  end

  private
  def output?(event)
    if !@type.empty?
      if event["type"] != @type
        @logger.debug? and @logger.debug("outputs/#{self.class.name}: Dropping event because type doesn't match",
                                         :type => @type, :event => event)
        return false
      end
    end

    if !@tags.empty?
      return false if !event["tags"]
      if (event["tags"] & @tags).size != @tags.size
        @logger.debug? and @logger.debug("outputs/#{self.class.name}: Dropping event because tags don't match",
                                         :tags => @tags, :event => event)
        return false
      end
    end

    if !@exclude_tags.empty? && event["tags"]
      if (diff_tags = (event["tags"] & @exclude_tags)).size != 0
        @logger.debug? and @logger.debug("outputs/#{self.class.name}: Dropping event because tags contains excluded tags",
                                         :diff_tags => diff_tags, :exclude_tags => @exclude_tags, :event => event)
        return false
      end
    end

    return true
  end
end # class LogStash::Outputs::Base
