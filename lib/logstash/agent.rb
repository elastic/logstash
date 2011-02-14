require "logstash/filters"
require "logstash/inputs"
require "logstash/logging"
require "logstash/multiqueue"
require "logstash/namespace"
require "logstash/outputs"
require "java"
require "uri"

JThread = java.lang.Thread

# Collect logs, ship them out.
class LogStash::Agent
  attr_reader :config
  attr_reader :inputs
  attr_reader :outputs
  attr_reader :filters

  public
  def initialize(config)
    log_to(STDERR)

    @config = config
    @threads = {}
    @outputs = []
    @inputs = []
    @filters = []
    # Config should have:
    # - list of logs to monitor
    #   - log config
    # - where to ship to

    Thread::abort_on_exception = true
  end # def initialize

  public
  def log_to(target)
    @logger = LogStash::Logger.new(target)
  end # def log_to

  public
  def run
    if @config["inputs"].length == 0 or @config["outputs"].length == 0
      raise "Must have both inputs and outputs configured."
    end

    # XXX we should use a SizedQueue here (w/config params for size)
    filter_queue = Queue.new
    output_queue = MultiQueue.new

    # Register input and output stuff
    input_configs = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }
    @config["inputs"].each do |url_type, urls|
      # url could be a string or an array.
      urls = [urls] if !urls.is_a?(Array)
      urls.each do |url_str|
        url = URI.parse(url_str)
        input_type = url.scheme
        input_configs[input_type][url_type] = url
      end
    end # each input

    input_configs.each do |input_type, config|
      if @config.include?("filters")
        queue = filter_queue
      else
        queue = output_queue
      end
      input = LogStash::Inputs.from_name(input_type, config, queue)
      @threads["input/#{input_type}"] = Thread.new do
        JThread.currentThread().setName("input/#{input_type}")
        input.run
      end
    end

    # Create N filter-worker threads
    if @config.include?("filters")
      3.times do |n|
        @threads["worker/filter/#{n}"] = Thread.new do
          JThread.currentThread().setName("worker/filter/#{n}")
          filters = []

          @config["filters"].collect { |x| x.to_a[0] }.each do |filter_config|
            name, value = filter_config
            @logger.info("Using filter #{name} => #{value.inspect}")
            filter = LogStash::Filters.from_name(name, value)
            filter.logger = @logger
            filter.register
            filters << filter
          end

          while event = filter_queue.pop
            filters.each do |filter|
              filter.filter(event)
              if event.cancelled?
                @logger.debug({:message => "Event cancelled",
                               :event => event,
                               :filter => filter.class,
                })
                break
              end
            end # filters.each

            output_queue.push(event) unless event.cancelled?
          end # event pop
        end # Thread
      end # N.times
    end # if @config.include?("filters")

    # Create output threads
    @config["outputs"].each do |url|
      queue = Queue.new
      @threads["outputs/#{url}"] = Thread.new do
        JThread.currentThread().setName("output:#{url}")
        output = LogStash::Outputs.from_url(url)
        while event = queue.pop
          output.receive(event)
        end
      end # Thread
      output_queue.add_queue(queue)
    end

    # Register any signal handlers
    #register_signal_handler

    while sleep 5
    end
  end # def register

  public
  def stop
    # TODO(petef): Stop inputs, fluch outputs, wait for finish,
    # then stop the event loop
  end # def stop

  protected
  def filter(event)
    @filters.each do |f|
      f.filter(event)
      break if event.cancelled?
    end
  end # def filter

  protected
  def output(event)
    @outputs.each do |o|
      o.receive(event)
    end # each output
  end # def output

  protected
  # Process a message
  def receive(event)
    filter(event)

    if !event.cancelled?
      output(event)
    end
  end # def input

  public
  def register_signal_handler
    @sigchannel = EventMachine::Channel.new
    Signal.trap("USR1") do
      @sigchannel.push(:USR1)
    end

    Signal.trap("INT") do
      @sigchannel.push(:INT)
    end

    @sigchannel.subscribe do |msg|
      case msg
      when :USR1
        counts = Hash.new { |h,k| h[k] = 0 }
        ObjectSpace.each_object do |obj|
          counts[obj.class] += 1
        end

        @logger.info("SIGUSR1 received. Dumping state")
        @logger.info("#{self.class.name} config")
        @logger.info(["  Inputs:", @inputs])
        @logger.info(["  Filters:", @filters])
        @logger.info(["  Outputs:", @outputs])

        @logger.info("Dumping counts of objects by class")
        counts.sort { |a,b| a[1] <=> b[1] or a[0] <=> b[0] }.each do |key, value|
          @logger.info("Class: [#{value}] #{key}")
        end
      when :INT
        @logger.warn("SIGINT received. Shutting down.")
        # TODO(petef): Should have input/output/filter register shutdown
        # hooks.
      end # case msg
    end # @sigchannel.subscribe
  end # def register_signal_handler
end # class LogStash::Agent
