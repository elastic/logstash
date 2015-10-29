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

  config :type, :validate => :string, :default => "", :obsolete => "You can achieve this same behavior with the new conditionals, like: `if [type] == \"sometype\" { %PLUGIN% { ... } }`."

  config :tags, :validate => :array, :default => [], :obsolete => "You can achieve similar behavior with the new conditionals, like: `if \"sometag\" in [tags] { %PLUGIN% { ... } }`"

  config :exclude_tags, :validate => :array, :default => [], :obsolete => "You can achieve similar behavior with the new conditionals, like: `if (\"sometag\" not in [tags]) { %PLUGIN% { ... } }`"

  # The codec used for output data. Output codecs are a convenient method for encoding your data before it leaves the output, without needing a separate filter in your Logstash pipeline.
  config :codec, :validate => :codec, :default => "plain"

  # The number of workers to use for this output.
  # Note that this setting may not be useful for all outputs.
  config :workers, :validate => :number, :default => 1

  attr_reader :worker_plugins, :worker_queue

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
    # TODO: noop for now, remove this once we delete this call from all plugins
    true
  end # def output?
end # class LogStash::Outputs::Base
