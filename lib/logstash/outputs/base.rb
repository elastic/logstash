# encoding: utf-8
require "logstash/event"
require "logstash/logging"
require "logstash/plugin"
require "logstash/namespace"
require "logstash/config/mixin"
require "logstash/util/wrapped_synchronous_queue"

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

    # If we're running with a single thread we must enforce single-threaded concurrency by default
    # Maybe in a future version we'll assume output plugins are threadsafe
    @single_worker_mutex = Mutex.new
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
    # TODO: Remove this branch, delete this function
    if @workers == 1
      @worker_plugins = [self]
    else
      define_singleton_method(:handle_batch, method(:handle_worker))

      @available_workers = SizedQueue.new(@worker_plugins.length)

      @worker_plugins = @workers.times.map { self.class.new(@original_params.merge("workers" => 1)) }

      @worker_plugins.each do |wp|
        wp.register
        @available_workers << wp
      end
    end
  end

  public
  # Not to be overriden by plugin authors!
  def handle(event)
    @single_worker_mutex.synchronize { receive(event) }
  end # def handle

  # To be overriden in implementations
  def receive_batch(events)
    events.each {|event|
      receive(event)
    }
  end

  # Not to be overriden by plugin authors!
  def handle_batch(events)
    @single_worker_mutex.synchronize { receive_batch(events) }
  end

  def handle_worker(events)
    worker = @available_workers.pop
    begin
      worker.handle_batch(events)
    ensure
      @available_workers.push(worker)
    end
  end

  def do_close
    if @worker_plugins
      @worker_plugins.each do |wp|
        wp.do_close
      end
    end
    super
  end

  private
  def output?(event)
    # TODO: noop for now, remove this once we delete this call from all plugins
    true
  end # def output?
end # class LogStash::Outputs::Base
