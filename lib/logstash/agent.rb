#TODO(sissel): Maybe this will help jruby jar issues?
#$: << File.join(File.dirname(__FILE__), "../"

require "java"
require "logstash/config/file"
require "logstash/filters"
require "logstash/filterworker"
require "logstash/inputs"
require "logstash/logging"
require "logstash/multiqueue"
require "logstash/namespace"
require "logstash/outputs"
require "logstash/util"
require "optparse"
require "thread"
require "uri"

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
  attr_reader :config_path
  attr_reader :daemonize
  attr_reader :logfile
  attr_reader :verbose

  public
  def initialize
    log_to(STDERR)

    # flag/config defaults
    @verbose = 0
    @daemonize = false

    @plugins = {}
    @plugins_mutex = Mutex.new
    @outputs = []
    @inputs = []
    @filters = []

    @plugin_paths = []

    # Add logstash's plugin path (plugin paths must contain inputs, outputs, filters)
    @plugin_paths << File.dirname(__FILE__)

    # TODO(sissel): Other default plugin paths?

    Thread::abort_on_exception = true
    @is_shutting_down = false
  end # def initialize

  public
  def log_to(target)
    @logger = LogStash::Logger.new(target)
  end # def log_to

  private
  def options(opts)
    opts.on("-f CONFIGPATH", "--config CONFIGPATH",
            "Load the logstash config from a specific file or directory. " \
            "If a direcory is given instead of a file, all files in that " \
            "directory will be concatonated in lexicographical order and " \
            "then parsed as a single config file.") do |arg|
      @config_path = arg
    end # -f / --config

    opts.on("-e CONFIGSTRING",
            "Use the given string as the configuration data. Same syntax as " \
            "the config file. If not input is specified, " \
            "'stdin { type => stdin }' is default. If no output is " \
            "specified, 'stdout { debug => true }}' is default.") do |arg|
      @config_string = arg
    end # -e

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
  def parse_options(args)
    @opts = OptionParser.new

    # Step one is to add agent flags.
    options(@opts)

    # TODO(sissel): Check for plugin_path flags, add them to @plugin_paths.
    args.each_with_index do |arg, index|
      next unless arg =~ /^(?:-p|--pluginpath)(?:=(.*))?$/
      path = $1
      if path.nil?
        path = args[index + 1]
      end

      @plugin_paths += path.split(":")
    end # args.each

    # At this point, we should load any plugin-specific flags.
    # These are 'unknown' flags that begin --<plugin>-flag
    # Put any plugin paths into the ruby library path for requiring later.
    @plugin_paths.each do |p|
      @logger.debug("Adding #{p.inspect} to ruby load path")
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
    args.each do |arg|
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
                @logger.debug("Found plugin class #{c}::#{klass_name})")
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
      remainder = @opts.parse(args)
    rescue OptionParser::InvalidOption => e
      @logger.info e
      raise e
    end
 
    return remainder
  end # def parse_options

  private
  def configure
    if @config_path && @config_string
      @logger.fatal "Can't use -f and -e at the same time"
      raise "Configuration problem"
    elsif (@config_path.nil? || @config_path.empty?) && @config_string.nil?
      @logger.fatal "No config file given. (missing -f or --config flag?)"
      @logger.fatal @opts.help
      raise "Configuration problem"
    end

    #if @config_path and !File.exist?(@config_path)
    if @config_path and Dir.glob(@config_path).length == 0
      @logger.fatal "Config file '#{@config_path}' does not exist."
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

    if @verbose >= 3  # Uber debugging.
      @logger.level = Logger::DEBUG
      $DEBUG = true
    elsif @verbose == 2 # logstash debug logs
      @logger.level = Logger::DEBUG
    elsif @verbose == 1 # logstash info logs
      @logger.level = Logger::INFO
    else # Default log level
      @logger.level = Logger::WARN
    end
  end # def configure

  public
  def run(args, &block)
    LogStash::Util::set_thread_name(self.class.name)
    register_signal_handlers

    remaining = parse_options(args)
    if remaining == false
      raise "Option parsing failed. See error log."
    end

    configure

    # Load the config file
    if @config_path
      # Support directory of config files.
      # https://logstash.jira.com/browse/LOGSTASH-106
      if File.directory?(@config_path)
        @logger.debug("Loading '#{@config_path}' as directory")
        paths = Dir.glob(File.join(@config_path, "*")).sort
      else
        # Get a list of files matching a glob. If the user specified a single
        # file, then this will only have one match and we are still happy.
        paths = Dir.glob(@config_path)
      end

      concatconfig = []
      paths.each do |path|
        concatconfig << File.new(path).read
      end
      config = LogStash::Config::File.new(nil, concatconfig.join("\n"))
    elsif @config_string
      # Given a config string by the user (via the '-e' flag)
      config = LogStash::Config::File.new(nil, @config_string)
    end

    @thread = Thread.new do
      run_with_config(config, &block)
    end

    return remaining
  end # def run

  public
  def wait
    @thread.join
  end

  public
  def run_with_config(config)
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

    # If we are given a config string (run usually with 'agent -e "some config string"')
    # then set up some defaults.
    if @config_string
      require "logstash/inputs/stdin"
      require "logstash/outputs/stdout"

      # set defaults if necessary
      
      # All filters default to 'stdin' type
      @filters.each do |filter|
        filter.type = "stdin" if filter.type.nil?
      end
      
      # If no inputs are specified, use stdin by default.
      @inputs = [LogStash::Inputs::Stdin.new("type" => [ "stdin" ])] if @inputs.length == 0

      # If no outputs are specified, use stdout in debug mode.
      @outputs = [LogStash::Outputs::Stdout.new("debug" => [ "true" ])] if @outputs.length == 0
    end

    if @inputs.length == 0 or @outputs.length == 0
      raise "Must have both inputs and outputs configured."
    end

    # NOTE(petef) we should use a SizedQueue here (w/config params for size)
    filter_queue = SizedQueue.new(10)
    output_queue = LogStash::MultiQueue.new

    @ready_queue = Queue.new

    # inputs should write directly to output queue if there are no filters.
    input_target = @filters.length > 0 ? filter_queue : output_queue
    # Start inputs
    @inputs.each do |input|
      @logger.debug(["Starting input", input])
      @plugins[input] = Thread.new(input, input_target) do |*args|
        run_input(*args)
      end
    end # @inputs.each

    # Create N filter-worker threads
    if @filters.length > 0
      1.times do |n|
        # TODO(sissel): facter this out into a 'filterworker' that  accepts
        # 'shutdown'
        # Start a filter worker
        filterworker = LogStash::FilterWorker.new(@filters, filter_queue,
                                                  output_queue)
        filterworker.logger = @logger
        @plugins[filterworker] = \
          Thread.new(filterworker, n, output_queue) do |*args|
            run_filter(*args)
          end
      end # N.times
    end # if @filters.length > 0


    # Create output threads
    @outputs.each do |output|
      queue = SizedQueue.new(10)
      output_queue.add_queue(queue)
      @plugins[output] = Thread.new(output, queue) do |*args|
        run_output(*args)
      end
    end # @outputs.each

    # Wait for all inputs and outputs to be registered.
    wait_count = outputs.size + inputs.size
    while wait_count > 0 and @ready_queue.pop 
      wait_count -= 1
    end

    # yield to a block in case someone's waiting for us to be done setting up
    # like tests, etc.
    yield if block_given?

    # TODO(sissel): Monitor what's going on? Sleep forever? what?
    while sleep 5
    end
  end # def run_with_config

  public
  def stop
    # TODO(petef): Stop inputs, fluch outputs, wait for finish,
    # then stop the event loop
  end # def stop

  # TODO(sissel): Is this method even used anymore?
  protected
  def filter(event)
    @filters.each do |f|
      f.filter(event)
      break if event.cancelled?
    end
  end # def filter

  # TODO(sissel): Is this method even used anymore?
  protected
  def output(event)
    # TODO(sissel): write to a multiqueue and do 1 thread per output?
    @outputs.each do |o|
      o.handle(event)
    end # each output
  end # def output

  # TODO(sissel): Is this method even used anymore?
  protected
  # Process a message
  def receive(event)
    filter(event)

    if !event.cancelled?
      output(event)
    end
  end # def input

  # Shutdown the agent.
  protected
  def shutdown
    return if @is_shutting_down

    @is_shutting_down = true
    Thread.new do
      @logger.info("Starting shutdown sequence")
      LogStash::Util::set_thread_name("logstash shutdown process")
      # TODO(sissel): Make this a flag
      force_shutdown_time = Time.now + 10

      finished_queue = Queue.new
      # Tell everything to shutdown.
      @logger.debug(@plugins.keys.collect(&:to_s))
      @plugins.each do |plugin, thread|
        @logger.debug("Telling to shutdown: #{plugin.to_s}")
        plugin.shutdown(finished_queue)
      end

      # Now wait until the queues we were given are empty.
      #@logger.debug(@plugins)
      remaining = @plugins.select { |plugin, thread| plugin.running? }
      while remaining.size > 0
        if (Time.now > force_shutdown_time)
          @logger.warn("Time to quit, even if some plugins aren't finished yet.")
          @logger.warn("Stuck plugins? #{remaining.map(&:first).join(", ")}")
          break
        end

        @logger.debug("Waiting for plugins to finish.")
        plugin = finished_queue.pop(non_block=true) rescue nil

        if plugin.nil?
          sleep(1)
        else
          remaining = @plugins.select { |plugin, thread| plugin.running? }
          @logger.debug("#{plugin.to_s} finished, waiting on " \
                        "#{remaining.size} plugins; " \
                        "#{remaining.map(&:first).join(", ")}")
        end
      end # while remaining.size > 0

      # When we get here, all inputs have finished, all messages are done
      @logger.info("Shutdown complete")
      java.lang.System.exit(0)
    end
  end # def shutdown

  public
  def register_signal_handlers
    # TODO(sissel): This doesn't work well in jruby since ObjectSpace is disabled
    # by default.
    #Signal.trap("USR2") do
      # TODO(sissel): Make this a function.
      #counts = Hash.new { |h,k| h[k] = 0 }
      #ObjectSpace.each_object do |obj|
        #counts[obj.class] += 1
      #end

      #@logger.info("SIGUSR1 received. Dumping state")
      #@logger.info("#{self.class.name} config")
      #@logger.info(["  Inputs:", @inputs])
      #@logger.info(["  Filters:", @filters])
      ##@logger.info(["  Outputs:", @outputs])

      #@logger.info("Dumping counts of objects by class")
      #counts.sort { |a,b| a[1] <=> b[1] or a[0] <=> b[0] }.each do |key, value|
        #@logger.info("Class: [#{value}] #{key}")
      ##end
    #end # SIGUSR1

    #Signal.trap("INT") do
      #@logger.warn("SIGINT received, shutting down.")
      #shutdown
    #end

    #Signal.trap("TERM") do
      #@logger.warn("SIGTERM received, shutting down.")
      #shutdown
    #end
  end # def register_signal_handlers

  private
  def run_input(input, queue)
    LogStash::Util::set_thread_name("input|#{input.to_s}")
    input.logger = @logger
    input.register

    @ready_queue << input
    done = false

    while !done
      begin
        input.run(queue)
        done = true
      rescue => e
        @logger.warn(["Input #{input.to_s} thread exception", e])
        @logger.debug(["Input #{input.to_s} thread exception backtrace",
                       e.backtrace])
        @logger.error("Restarting input #{input.to_s} due to exception")
        sleep(1)
        retry # This jumps to the top of this proc (to the start of 'do'
      end
    end

    @logger.warn("Input #{input.to_s} shutting down")

    # If we get here, the plugin finished, check if we need to shutdown.
    shutdown_if_none_running(LogStash::Inputs::Base, queue)
  end # def run_input

  # Run a filter thread
  public
  def run_filter(filterworker, index, output_queue)
    LogStash::Util::set_thread_name("filter|worker|#{index}")
    filterworker.run

    @logger.warn("Filter worker ##{index} shutting down")

    # If we get here, the plugin finished, check if we need to shutdown.
    shutdown_if_none_running(LogStash::FilterWorker, output_queue)
  end # def run_filter

  # TODO(sissel): Factor this into an 'outputworker'
  def run_output(output, queue)
    LogStash::Util::set_thread_name("output|#{output.to_s}")
    output.register
    output.logger = @logger
    @ready_queue << output

    # TODO(sissel): We need a 'reset' or 'restart' method to call on errors

    begin
      while event = queue.pop do
        @logger.debug("Sending event to #{output.to_s}")
        output.handle(event)
      end
    rescue Exception => e
      @logger.warn(["Output #{output.to_s} thread exception", e])
      @logger.debug(["Output #{output.to_s} thread exception backtrace",
                     e.backtrace])
      # TODO(sissel): should we abort after too many failures?
      sleep(1)
      retry
    end # begin/rescue
 
    @logger.warn("Output #{input.to_s} shutting down")

    # If we get here, the plugin finished, check if we need to shutdown.
    shutdown_if_none_running(LogStash::Outputs::Base)
  end # def run_output

  def shutdown_if_none_running(pluginclass, queue=nil)
    # Send shutdown signal if all inputs are done.
    @plugins_mutex.synchronize do

      # Look for plugins of type 'pluginclass' (or a subclass)
      # If none are running, start the shutdown sequence and
      # send the 'shutdown' event down the pipeline.
      remaining = @plugins.count do |plugin, thread|
        plugin.is_a?(pluginclass) and plugin.running?
      end
      @logger.debug("#{pluginclass} still running: #{remaining}")

      if remaining == 0
        @logger.debug("All #{pluginclass} finished. Shutting down.")
        
        # Send 'shutdown' to the filters.
        queue << LogStash::SHUTDOWN if !queue.nil?
        shutdown
      end # if remaining == 0
    end # @plugins_mutex.synchronize
  end # def shutdown_if_none_running
end # class LogStash::Agent

if __FILE__ == $0
  $: << "net"
  agent = LogStash::Agent.new
  agent.argv = ARGV
  agent.run
end
