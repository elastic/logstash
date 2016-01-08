# encoding: utf-8
require "concurrent/atomic/atomic_fixnum"

# This class goes hand in hand with the pipeline to provide a pool of
# free workers to be used by pipeline worker threads. The pool is
# internally represented with a SizedQueue set the the size of the number
# of 'workers' the output plugin is configured with.
#
# This plugin also records some basic statistics
module LogStash class OutputDelegator
  attr_reader :workers, :config, :worker_count, :threadsafe

  # The *args this takes are the same format that a Outputs::Base takes. A list of hashes with parameters in them
  # Internally these just get merged together into a single hash
  def initialize(logger, klass, default_worker_count, *args)
    @logger = logger
    @threadsafe = klass.threadsafe?
    @config = args.reduce({}, :merge)
    @klass = klass

    # We define this as an array regardless of threadsafety
    # to make reporting simpler, even though a threadsafe plugin will just have
    # a single instance
    #
    # Older plugins invoke the instance method Outputs::Base#workers_not_supported
    # To detect these we need an instance to be created first :()
    # TODO: In the next major version after 2.x remove support for this
    @workers = [@klass.new(*args)]
    @workers.first.register # Needed in case register calls `workers_not_supported`

    # DO NOT move this statement before the instantiation of the first single instance
    # Read the note above to understand why
    @worker_count = calculate_worker_count(default_worker_count)
    @logger.debug("Will start workers for output", :worker_count => @worker_count, :class => klass)

    warn_on_worker_override!
    # This queue is used to manage sharing across threads
    @worker_queue = SizedQueue.new(@worker_count)

    @workers += (@worker_count - 1).times.map do
      inst = @klass.new(*args)
      inst.register
      inst
    end

    @workers.each { |w| @worker_queue << w }

    @events_received = Concurrent::AtomicFixnum.new(0)


    # One might wonder why we don't use something like
    # define_singleton_method(:multi_receive, method(:threadsafe_multi_receive)
    # and the answer is this is buggy on Jruby 1.7.x . It works 98% of the time!
    # The other 2% you get weird errors about rebinding to the same object
    # Until we switch to Jruby 9.x keep the define_singleton_method parts
    # the way they are, with a block
    # See https://github.com/jruby/jruby/issues/3582
    if threadsafe?
      @threadsafe_worker = @workers.first
      define_singleton_method(:multi_receive) do |events|
        threadsafe_multi_receive(events)
      end
    else
      define_singleton_method(:multi_receive) do |events|
        worker_multi_receive(events)
      end
    end
  end

  def threadsafe?
    !!@threadsafe
  end

  def warn_on_worker_override!
    # The user has configured extra workers, but this plugin doesn't support it :(
    if worker_limits_overriden?
      message = @klass.workers_not_supported_message
      warning_meta = {:plugin => @klass.config_name, :worker_count => @config["workers"]}
      if message
        warning_meta[:message] = message
        @logger.warn(I18n.t("logstash.pipeline.output-worker-unsupported-with-message", warning_meta))
      else
        @logger.warn(I18n.t("logstash.pipeline.output-worker-unsupported", warning_meta))
      end
    end
  end

  def worker_limits_overriden?
    @config["workers"] && @config["workers"] > 1 && @klass.workers_not_supported?
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

  private
  # Needed for testing, so private
  attr_reader :threadsafe_worker, :worker_queue
end end