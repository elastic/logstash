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

  # The codec used for output data
  config :codec, :validate => :codec, :default => "plain"

  # The number of workers to use for this output.
  # Note that this setting may not be useful for all outputs.
  config :workers, :validate => :number, :default => 1

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
    return unless @workers > 1

    define_singleton_method(:handle, method(:handle_worker))
    @worker_queue = SizedQueue.new(20)

    @worker_threads = @workers.times do |i|
      Thread.new(original_params, @worker_queue) do |params, queue|
        LogStash::Util::set_thread_name(">#{self.class.config_name}.#{i}")
        worker_params = params.merge("workers" => 1, "codec" => @codec.clone)
        worker_plugin = self.class.new(worker_params)
        worker_plugin.register
        while true
          event = queue.pop
          worker_plugin.handle(event)
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
    return true
  end
end # class LogStash::Outputs::Base
