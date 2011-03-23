#TODO(sissel): Maybe this will help jruby jar issues?
#$: << File.join(File.dirname(__FILE__), "../"

require "logstash/filters"
require "logstash/inputs"
require "logstash/logging"
require "logstash/multiqueue"
require "logstash/namespace"
require "logstash/outputs"
require "logstash/config/file"
require "optparse"
require "java"
require "uri"

JThread = java.lang.Thread

# TODO(sissel): only enable this if we are in debug mode.
# JRuby.objectspace=true

# Collect logs, ship them out.
class LogStash::Agent
  attr_reader :config
  attr_reader :inputs
  attr_reader :outputs
  attr_reader :filters
  attr_accessor :logger

  # flags
  attr_reader :config_file
  attr_reader :daemonize
  attr_reader :logfile
  attr_reader :verbose

  public
  def initialize
    log_to(STDERR)

    # flag/config defaults
    @verbose = 0
    @daemonize = false

    @threads = {}
    @outputs = []
    @inputs = []
    @filters = []

    @plugin_paths = []

    # Add logstash's plugin path (plugin paths must contain inputs, outputs, filters)
    @plugin_paths << File.dirname(__FILE__)

    # TODO(sissel): Other default plugin paths?

    Thread::abort_on_exception = true
  end # def initialize

  public
  def log_to(target)
    @logger = LogStash::Logger.new(target)
  end # def log_to

  public
  def argv=(argv)
    @argv = argv
  end

  private
  def options(opts)
    opts.on("-f CONFIGFILE", "--config CONFIGFILE",
            "Load the logstash config from a specific file") do |arg|
      @config_file = arg
    end

    opts.on("-d", "--daemonize", "Daemonize (default is run in foreground)") do 
      @daemonize = true
    end

    opts.on("-l", "--log FILE", "Log to a given path. Default is stdout.") do |path|
      @logfile = path
    end

    opts.on("-v", "Increase verbosity") do
      @verbose += 1
    end

    opts.on("-p PLUGIN_PATH", "--pluginpath PLUGIN_PATH",
            "A colon-delimited path to find plugins in.") do |path|
      path.split(":").each do |p|
        @plugin_paths << p unless @plugin_paths.include?(p)
      end
    end
  end # def options

  # Parse options.
  private
  def parse_options
    @opts = OptionParser.new

    # Step one is to add agent flags.
    options(@opts)

    # TODO(sissel): Check for plugin_path flags, add them to @plugin_paths.
    @argv.each_with_index do |arg, index|
      next unless arg =~ /^(?:-p|--pluginpath)(?:=(.*))?$/
      path = $1
      if path.nil?
        path = @argv[index + 1]
      end

      @plugin_paths += path.split(":")
    end # @argv.each

    # At this point, we should load any plugin-specific flags.
    # These are 'unknown' flags that begin --<plugin>-flag
    # Put any plugin paths into the ruby library path for requiring later.
    @plugin_paths.each do |p|
      @logger.info "Adding #{p.inspect} to ruby load path"
      $:.unshift p
    end

    # TODO(sissel): Go through all inputs, filters, and outputs to get the flags.
    # Add plugin flags to @opts

    # Load any plugins that we have flags for.
    # TODO(sissel): The --<plugin> flag support currently will load
    # any matching plugins input, output, or filter. This means, for example,
    # that the 'amqp' input *and* output plugin will be loaded if you pass
    # --amqp-foo flag. This might cause confusion, but it seems reasonable for
    # now that any same-named component will have the same flags.
    plugins = []
    @argv.each do |arg|
      # skip things that don't look like plugin flags
      next unless arg =~ /^--[A-z0-9]+-/ 
      name = arg.split("-")[2]  # pull the plugin name out

      # Try to load any plugin by that name
      %w{inputs outputs filters}.each do |component|
        @plugin_paths.each do |path|
          plugin = File.join(path, component, name) + ".rb"
          @logger.debug("Flag #{arg} found; trying to load #{plugin}")
          if File.file?(plugin)
            @logger.info("Loading plugin #{plugin}")
            require plugin
            [LogStash::Inputs, LogStash::Filters, LogStash::Outputs].each do |c|
              # If we get flag --foo-bar, check for LogStash::Inputs::Foo
              # and add any options to our option parser.
              klass_name = name.capitalize
              if c.const_defined?(klass_name)
                @logger.info("Found plugin class #{c}::#{klass_name})")
                klass = c.const_get(klass_name)
                # See LogStash::Config::Mixin::DSL#options
                klass.options(@opts)
                plugins << klass
              end # c.const_defined?
            end # each component type (input/filter/outputs)
          end # if File.file?(plugin)
        end # @plugin_paths.each
      end # %{inputs outputs filters}.each

      #if !found
        #@logger.fatal("Flag #{arg.inspect} requires plugin #{name}, but no plugin found.")
        #return false
      #end
    end # @remaining_args.each 
   
    begin
      @opts.parse!(@argv)
    rescue OptionParser::InvalidOption => e
      @logger.info e
      raise e
    end
 
    return true
  end # def parse_options

  private
  def configure
    if @config_file.nil? || @config_file.empty?
      @logger.fatal "No config file given. (missing -f or --config flag?)"
      @logger.fatal @opts.help
      raise "Configuration problem"
    end

    if !File.exist?(@config_file)
      @logger.fatal "Config file '#{@config_file}' does not exist."
      raise "Configuration problem"
    end

    if @daemonize
      @logger.fatal "Can't daemonize, no support yet in JRuby."
      raise "Can't daemonize, no fork in JRuby."
    end

    if @logfile
      logfile = File.open(@logfile, "w")
      STDOUT.reopen(logfile)
      STDERR.reopen(logfile)
    elsif @daemonize
      devnull = File.open("/dev/null", "w")
      STDOUT.reopen(devnull)
      STDERR.reopen(devnull)
    end

    if @verbose > 2
      @logger.level = Logger::DEBUG
    elsif @verbose == 1
      @logger.level = Logger::INFO
    else
      # Default log level
      @logger.level = Logger::WARN
    end
  end # def configure

  public
  def run
    JThread.currentThread().setName(self.class.name)
    ok = parse_options
    if !ok
      raise "Option parsing failed. See error log."
    end


    configure

    # Load the config file
    config = LogStash::Config::File.new(@config_file)
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
    #filter_queue = Queue.new
    filter_queue = SizedQueue.new(10)
    output_queue = LogStash::MultiQueue.new

    input_target = @filters.length > 0 ? filter_queue : output_queue
    # Start inputs
    @inputs.each do |input|
      @logger.info(["Starting input", input])
      @threads[input] = Thread.new(input_target) do |input_target|
        input.logger = @logger
        input.register
        input.run(input_target)
      end # new thread for thsi input
    end # @inputs.each

    # Create N filter-worker threads
    if @filters.length > 0
      1.times do |n|
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

            @logger.debug(["Event finished filtering", event])
            output_queue.push(event) unless event.cancelled?
          end # event pop
        end # Thread.new
      end # N.times
    end # if @filters.length > 0


    # Create output threads
    @outputs.each do |output|
      queue = SizedQueue.new(10)
      output_queue.add_queue(queue)
      @threads["outputs/#{output.to_s}"] = Thread.new(queue) do |queue|
        output.register
        begin
          JThread.currentThread().setName("output/#{output.to_s}")
          output.logger = @logger

          while event = queue.pop do
            @logger.debug("Sending event to #{output.to_s}")
            output.receive(event)
          end
        rescue Exception => e
          @logger.warn(["Output #{output.to_s} thread exception", e])
          retry
        end
      end # Thread.new
    end # @outputs.each

    while sleep 5
    end
  end # def run

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
    # TODO(sissel): This doesn't work well in jruby since ObjectSpace is disabled
    # by default.
    Signal.trap("USR2") do
      # TODO(sissel): Make this a function.
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
    end # SIGUSR1
  end # def register_signal_handler
end # class LogStash::Agent

if __FILE__ == $0
  $: << "net"
  agent = LogStash::Agent.new
  agent.argv = ARGV
  agent.run
end
