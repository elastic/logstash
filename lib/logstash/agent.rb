require "logstash/filters"
require "logstash/inputs"
require "logstash/logging"
require "logstash/multiqueue"
require "logstash/namespace"
require "logstash/outputs"
require "logstash/config/file"
require "java"
require "uri"

JThread = java.lang.Thread

# Collect logs, ship them out.
class LogStash::Agent
  attr_reader :config
  attr_reader :inputs
  attr_reader :outputs
  attr_reader :filters
  attr_accessor :logger

  public
  def initialize(settings)
    log_to(STDERR)

    @settings = settings
    @threads = {}
    @outputs = []
    @inputs = []
    @filters = []

    Thread::abort_on_exception = true
  end # def initialize

  public
  def log_to(target)
    @logger = LogStash::Logger.new(target)
  end # def log_to

  public
  def run
    JThread.currentThread().setName("agent")

    # Load the config file
    config = LogStash::Config::File.new(@settings.config_file)
    config.parse do |plugin|
      # 'plugin' is a has containing:
      #   :type => the base class of the plugin (LogStash::Inputs::Base, etc)
      #   :plugin => the class of the plugin (LogStash::Inputs::File, etc)
      #   :parameters => hash of key-value parameters from the config.
      type = plugin[:type].config_name  # "input" or "filter" etc...
      klass = plugin[:plugin]

      # Create a new instance of a plugin, called like:
      # -> LogStash::Inputs::File.new( params )
      instance = klass.new(plugin[:parameters])
      instance.logger = @logger

      case type
        when "input"
          @inputs << instance
        when "filter"
          @filters << instance
        when "output"
          @outputs << instance
        else
          @logger.error("Unknown config type '#{type}'")
          exit 1
      end # case type
    end # config.parse

    if @inputs.length == 0 or @outputs.length == 0
      raise "Must have both inputs and outputs configured."
    end

    # NOTE(petef) we should use a SizedQueue here (w/config params for size)
    filter_queue = Queue.new
    output_queue = MultiQueue.new

    queue = @filters.length > 0 ? filter_queue : output_queue
    # Start inputs
    @inputs.each do |input|
      @logger.info(["Starting input", input])
      @threads[input] = Thread.new do
        input.logger = @logger
        input.register
        input.run(queue)
      end
    end

    # Create N filter-worker threads
    if @filters.length > 0
      3.times do |n|
        @logger.info("Starting filter worker thread #{n}")
        @threads["filter|worker|#{n}"] = Thread.new do
          JThread.currentThread().setName("filter|worker|#{n}")
          @filters.each do |filter|
            filter.logger = @logger
            filter.register
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
        end # Thread.new
      end # N.times
    end # if @filters.length > 0


    # Create output threads
    @outputs.each do |output|
      queue = Queue.new
      output_queue.add_queue(queue)

      @threads["outputs/#{output}"] = Thread.new do
        JThread.currentThread().setName("output/#{output}")
        output.logger = @logger
        output.register

        while event = queue.pop do
          output.receive(event)
        end
      end # Thread.new
    end # @outputs.each


#    # Register any signal handlers
#    #register_signal_handler
#
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
      # TODO(sissel): Make this a function.
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
