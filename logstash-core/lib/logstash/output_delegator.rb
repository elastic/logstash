# encoding: utf-8
require "concurrent/atomic/atomic_fixnum"

# This class goes hand in hand with the pipeline to provide a pool of
# free workers to be used by pipeline worker threads. The pool is
# internally represented with a SizedQueue set the the size of the number
# of 'workers' the output plugin is configured with.
#
# This plugin also records some basic statistics
module LogStash; class OutputDelegator
  attr_reader :workers, :config, :worker_count

  # The *args this takes are the same format that a Outputs::Base takes. A list of hashes with parameters in them
  # Internally these just get merged together into a single hash
  def initialize(logger, klass, *args)
    @logger = logger
    @config = args.reduce({}, :merge)
    @klass = klass
    @worker_count = @config["workers"] || 1

    @worker_queue = SizedQueue.new(@worker_count)

    @workers = @worker_count.times.map do
      w = @klass.new(*args)
      w.register
      @worker_queue << w
      w
    end

    @events_received = Concurrent::AtomicFixnum.new(0)
  end

  def config_name
    @klass.config_name
  end

  def register
    @workers.each {|w| w.register}
  end

  def multi_receive(events)
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

  def busy_workers
    @worker_queue.size
  end
end end