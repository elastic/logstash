# encoding: utf-8
require "concurrent/atomic/atomic_fixnum"

# This class goes hand in hand with the pipeline to provide a pool of
# free workers to be used by pipeline worker threads. The pool is
# internally represented with a SizedQueue set the the size of the number
# of 'workers' the output plugin is configured with.
#
# This plugin also records some basic statistics
module LogStash; class OutputDelegator
  attr_reader :workers, :config, :worker_count, :threadsafe

  # The *args this takes are the same format that a Outputs::Base takes. A list of hashes with parameters in them
  # Internally these just get merged together into a single hash
  def initialize(logger, klass, default_worker_count, *args)
    @logger = logger
    @threadsafe = klass.threadsafe?
    @config = args.reduce({}, :merge)
    @klass = klass
    @worker_count = calculate_worker_count(default_worker_count)

    warn_on_worker_override!

    @worker_queue = SizedQueue.new(@worker_count)

    # We define this as an array regardless of threadsafety
    # to make reporting simpler
    @workers = @worker_count.times.map do
      w = @klass.new(*args)
      w.register
      @worker_queue << w
      w
    end


    @events_received = Concurrent::AtomicFixnum.new(0)

    if threadsafe
      @threadsafe_worker = @workers.first
      self.define_singleton_method(:multi_receive, method(:threadsafe_multi_receive))
    else
      self.define_singleton_method(:multi_receive, method(:worker_multi_receive))
    end
  end

  def warn_on_worker_override!
    # The user has configured extra workers, but this plugin doesn't support it :(
    if @config["workers"] && @config["workers"] > 1 && @klass.workers_not_supported?
      message = @workers_not_supported_message
      if message
        @logger.warn(I18n.t("logstash.pipeline.output-worker-unsupported-with-message", :plugin => self.class.config_name, :worker_count => @workers, :message => message))
      else
        @logger.warn(I18n.t("logstash.pipeline.output-worker-unsupported", :plugin => self.class.config_name, :worker_count => @workers))
      end
    end
  end

  def calculate_worker_count(default_worker_count)
    if @threadsafe || @klass.workers_not_supported?
      1
    else
      @config["workers"] || default_worker_count
    end
  end

  def config_name
    @klass.config_name
  end

  def register
    @workers.each {|w| w.register}
  end

  # Threadsafe outputs have a much simpler
  def threadsafe_multi_receive(events)
    @events_received.increment(events.length)

    @threadsafe_worker.multi_receive(events)
  end

  def worker_multi_receive(events)
    @events_received.increment(events.length)

    worker = @worker_queue.pop
    begin
      worker.multi_receive(events)
    ensure
      @worker_queue.push(worker)
    end
  end

  def do_close
    @logger.debug("closing output delegator", :klass => self)

    @worker_count.times do
      worker = @worker_queue.pop
      worker.do_close
    end
  end

  def events_received
    @events_received.value
  end

  # There's no concept of 'busy' workers for a threadsafe plugin!
  def busy_workers
    if @threadsafe
      0
    else
      @workers.size - @worker_queue.size
    end
  end
end end