require "logstash/config/file"
require "logstash/config/file/yaml"
require "logstash/filterworker"
require "logstash/logging"
require "logstash/sized_queue"
require "logstash/multiqueue"
require "logstash/namespace"
require "logstash/program"
require "logstash/threadwatchdog"
require "logstash/util"
require "optparse"
require "thread"
require "uri"

# TODO(sissel): only enable this if we are in debug mode.
# JRuby.objectspace=true

# Collect logs, ship them out.
class LogStash::Agent
  include LogStash::Program

  attr_reader :config
  attr_reader :inputs
  attr_reader :outputs
  attr_reader :filters
  attr_accessor :logger

  # flags
  attr_reader :config_path
  attr_reader :logfile
  attr_reader :verbose

  public
  def initialize
    log_to(STDERR)
    @config_path = nil
    @config_string = nil
    @is_yaml = false
    @logfile = nil

    # flag/config defaults
    @verbose = 0
    @filterworker_count = 1
    @watchdog_timeout = 10

    @plugins = {}
    @plugins_mutex = Mutex.new
    @plugin_setup_mutex = Mutex.new
    @outputs = []
    @inputs = []
    @filters = []

    @plugin_paths = []
    @reloading = false

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

    opts.on("-w COUNT", "--filterworkers COUNT", Integer,
            "Run COUNT filter workers (default: 1)") do |arg|
      @filterworker_count = arg
      if @filterworker_count <= 0
        raise ArgumentError, "filter worker count must be > 0"
      end
    end # -w

    opts.on("--watchdog-timeout TIMEOUT", "Set watchdog timeout value") do |arg|
      @watchdog_timeout = arg.to_f
    end # --watchdog-timeout

    opts.on("-l", "--log FILE", "Log to a given path. Default is stdout.") do |path|
      @logfile = path
    end

    opts.on("-v", "Increase verbosity") do
      @verbose += 1
    end

    opts.on("-V", "--version", "Show the version of logstash") do
      require "logstash/version"
      puts "logstash #{LOGSTASH_VERSION}"
      exit(0)
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
      @logger.debug? and @logger.debug("Adding to ruby load path", :path => p)
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
          @logger.debug? and @logger.debug("Plugin flag found; trying to load it",
                                           :flag => arg, :plugin => plugin)
          if File.file?(plugin)
            @logger.info("Loading plugin", :plugin => plugin)
            require plugin
            [LogStash::Inputs, LogStash::Filters, LogStash::Outputs].each do |c|
              # If we get flag --foo-bar, check for LogStash::Inputs::Foo
              # and add any options to our option parser.
              klass_name = name.capitalize
              if c.const_defined?(klass_name)
                @logger.debug? and @logger.debug("Found plugin class", :class => "#{c}::#{klass_name})")
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
      @logger.info("Invalid option", :exception => e)
      raise e
    end

    return remainder
  end # def parse_options

  private
  def configure
    if @config_path && @config_string
      @logger.fatal("Can't use -f and -e at the same time")
      raise "Configuration problem"
    elsif (@config_path.nil? || @config_path.empty?) && @config_string.nil?
      @logger.fatal("No config file given. (missing -f or --config flag?)")
      @logger.fatal(@opts.help)
      raise "Configuration problem"
    end

    #if @config_path and !File.exist?(@config_path)
    if @config_path and Dir.glob(@config_path).length == 0
      @logger.fatal("Config file does not exist.", :path => @config_path)
      raise "Configuration problem"
    end

    if @logfile
      logfile = File.open(@logfile, "a")
      STDOUT.reopen(logfile)
      STDERR.reopen(logfile)
    end

    if ENV.include?("RUBY_DEBUG")
      $DEBUG = true
    end

    if @verbose >= 2 # logstash debug logs
      @logger.level = :debug
    elsif @verbose == 1 # logstash info logs
      @logger.level = :info
    else # Default log level
      @logger.level = :warn
    end
  end # def configure

  def read_config
    if @config_path
      # Support directory of config files.
      # https://logstash.jira.com/browse/LOGSTASH-106
      if File.directory?(@config_path)
        @logger.debug? and @logger.debug("Config path is a directory, scanning files",
                                         :path => @config_path)
        paths = Dir.glob(File.join(@config_path, "*")).sort
      else
        # Get a list of files matching a glob. If the user specified a single
        # file, then this will only have one match and we are still happy.
        paths = Dir.glob(@config_path).sort
      end

      concatconfig = []
      paths.each do |path|
        file = File.new(path)
        if File.extname(file) == '.yaml'
          # assume always YAML if even one file is
          @is_yaml = true
        end
        concatconfig << file.read
      end
      config_data = concatconfig.join("\n")
    else # @config_string
      # Given a config string by the user (via the '-e' flag)
      config_data = @config_string
    end

    if @is_yaml
      config = LogStash::Config::File::Yaml.new(nil, config_data)
    else
      config = LogStash::Config::File.new(nil, config_data)
    end

    config.logger = @logger
    config
  end

  # Parses a config and returns [inputs, filters, outputs]
  def parse_config(config)
    inputs = []
    filters = []
    outputs = []
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
          inputs << instance
        when "filter"
          filters << instance
        when "output"
          outputs << instance
        else
          msg = "Unknown config type '#{type}'"
          @logger.error(msg)
          raise msg
      end # case type
    end # config.parse
    return inputs, filters, outputs
  end

  public
  def run(args, &block)
    @logger.info("Register signal handlers")
    register_signal_handlers

    @logger.info("Parse options ")
    remaining = parse_options(args)
    if remaining == false
      raise "Option parsing failed. See error log."
    end

    @logger.info("Configure")
    configure

    # Load the config file
    @logger.info("Read config")
    config = read_config

    @logger.info("Start thread")
    @thread = Thread.new do
      LogStash::Util::set_thread_name(self.class.name)
      run_with_config(config, &block)
    end

    return remaining
  end # def run

  public
  def wait
    @thread.join
    return 0
  end # def wait

  private
  def start_input(input)
    @logger.debug? and @logger.debug("Starting input", :plugin => input)
    t = 0
    # inputs should write directly to output queue if there are no filters.
    input_target = @filters.length > 0 ? @filter_queue : @output_queue
    # check to see if input supports multiple threads
    if input.threadable
      @logger.debug? and @logger.debug("Threadable input", :plugin => input)
      # start up extra threads if need be
      (input.threads-1).times do
        input_thread = input.clone
        @logger.debug? and @logger.debug("Starting thread", :plugin => input, :thread => (t+=1))
        @plugins[input_thread] = Thread.new(input_thread, input_target) do |*args|
          run_input(*args)
        end
      end
    end
    @logger.debug? and @logger.debug("Starting thread", :plugin => input, :thread => (t+=1))
    @plugins[input] = Thread.new(input, input_target) do |*args|
      run_input(*args)
    end
  end

  private
  def start_output(output)
    @logger.debug? and @logger.debug("Starting output", :plugin => output)
    queue = LogStash::SizedQueue.new(10 * @filterworker_count)
    queue.logger = @logger
    @output_queue.add_queue(queue)
    @output_plugin_queues[output] = queue
    @plugins[output] = Thread.new(output, queue) do |*args|
      run_output(*args)
    end
  end


  public
  def run_with_config(config)
    @plugins_mutex.synchronize do
      @inputs, @filters, @outputs = parse_config(config)

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

      # NOTE(petef) we should have config params for queue size
      @filter_queue = LogStash::SizedQueue.new(10 * @filterworker_count)
      @filter_queue.logger = @logger
      @output_queue = LogStash::MultiQueue.new
      @output_queue.logger = @logger

      @ready_queue = Queue.new

      # Start inputs
      @inputs.each do |input|
        start_input(input)
      end # @inputs.each

      # Create N filter-worker threads
      @filterworkers = {}
      if @filters.length > 0
        @filters.each do |filter|
          filter.logger = @logger
          @plugin_setup_mutex.synchronize do
            filter.register
          end
        end

        if @filterworker_count > 1
          @filters.each do |filter|
            if ! filter.threadsafe?
                raise "fail"
            end
          end
        end

        @filterworker_count.times do |n|
          # TODO(sissel): facter this out into a 'filterworker' that  accepts
          # 'shutdown'
          # Start a filter worker
          filterworker = LogStash::FilterWorker.new(@filters, @filter_queue,
                                                    @output_queue)
          filterworker.logger = @logger
          thread = Thread.new(filterworker, n, @output_queue) do |*args|
            run_filter(*args)
          end
          @plugins[filterworker] = thread
          @filterworkers[filterworker] = thread
        end # N.times
      end # if @filters.length > 0

      # A thread to supervise filter workers
      watchdog = LogStash::ThreadWatchdog.new(@filterworkers.values,
                                              @watchdog_timeout)
      watchdog.logger = logger
      Thread.new do
        watchdog.watch
      end

      # Create output threads
      @output_plugin_queues = {}
      @outputs.each do |output|
        start_output(output)
      end # @outputs.each

      # Wait for all inputs and outputs to be registered.
      wait_count = outputs.size + inputs.size
      while wait_count > 0 and @ready_queue.pop
        wait_count -= 1
      end
      @logger.info("All plugins are started and registered.")
    end # synchronize

    # yield to a block in case someone's waiting for us to be done setting up
    # like tests, etc.
    yield if block_given?

    while sleep(2)
      if @plugins.values.count { |p| p.alive? } == 0
        @logger.warn("no plugins running, shutting down")
        shutdown
        break
      end
      @logger.debug? and @logger.debug("heartbeat")
    end
  end # def run_with_config

  public
  def stop
    # TODO(petef): Stop inputs, fluch outputs, wait for finish,
    # then stop the event loop
  end # def stop

  # Shutdown the agent.
  protected
  def shutdown
    @logger.info("Starting shutdown sequence")
    shutdown_plugins(@plugins)
    # When we get here, all inputs have finished, all messages are done
    @logger.info("Shutdown complete")

    # The 'unless $TESTING' is a hack for now to work around the test suite
    # needing the pipeline to finish cleanly. We should just *not* exit here,
    # but many plugins don't shutdown correctly. Fixing that shutdown problem
    # will require a new pipeline design that has shutdown contracts built-in
    # to the plugin<->agent protocol.
    #
    # For now, to make SIGINT/SIGTERM actually shutdown, exit. Unless we are
    # testing, in which case wait properly for shutdown. Shitty solution, but
    # whatever. We'll hopefully have a new pipeline/plugin protocol design
    # shortly (by November 2012?) that will resolve this hack.
    exit(0) unless $TESTING
  end # def shutdown

  def shutdown_plugins(plugins)
    return if @is_shutting_down

    @is_shutting_down = true
    Thread.new do
      LogStash::Util::set_thread_name("logstash shutdown process")
      # TODO(sissel): Make this a flag
      force_shutdown_time = Time.now + 10

      finished_queue = Queue.new
      # Tell everything to shutdown.
      @logger.debug("Plugins to shutdown", :plugins => plugins.keys.collect(&:to_s))
      plugins.each do |p, thread|
        @logger.debug("Sending shutdown to: #{p.to_s}", :plugin => p)
        p.shutdown(finished_queue)
      end

      # Now wait until the queues we were given are empty.
      #@logger.debug(@plugins)
      remaining = plugins.select { |p, thread| p.running? }
      while remaining.size > 0
        if (Time.now > force_shutdown_time)
          @logger.warn("Time to quit, even if some plugins aren't finished yet.")
          @logger.warn("Stuck plugins?", :remaining => remaining.map(&:first))
          break
        end

        @logger.debug("Waiting for plugins to finish.")
        plugin = finished_queue.pop(non_block=true) rescue nil

        if plugin.nil?
          sleep(1)
        else
          remaining = plugins.select { |p, thread| plugin.running? }
          @logger.debug("Plugin #{p.to_s} finished, waiting on the rest.",
                        :count => remaining.size,
                        :remaining => remaining.map(&:first))
        end
      end # while remaining.size > 0
    end
    @is_shutting_down = false
  end



  # Reload configuration of filters, etc.
  def reload
    @plugins_mutex.synchronize do
      begin
        @reloading = true
        # Reload the config file
        begin
          config = read_config
          reloaded_inputs, reloaded_filters, reloaded_outputs = parse_config(config)
        rescue Exception => e
          @logger.error("Aborting reload due to bad configuration", :exception => e)
          return
        end

        new_inputs = reloaded_inputs - @inputs
        new_filters = reloaded_filters - @filters
        new_outputs = reloaded_outputs - @outputs

        deleted_inputs = @inputs - reloaded_inputs
        deleted_filters = @filters - reloaded_filters
        deleted_outputs = @outputs - reloaded_outputs


        # Handle shutdown of input and output plugins
        obsolete_plugins = {}
        [deleted_inputs].flatten.each do |p|
          if @plugins.include? p
            obsolete_plugins[p] = @plugins[p]
            @plugins.delete(p)
          else
            @logger.warn("Couldn't find input plugin to stop", :plugin => p)
          end
        end

        [deleted_outputs].flatten.each do |p|
          if @plugins.include? p
            obsolete_plugins[p] = @plugins[p]
            @plugins.delete(p)
            @output_queue.remove_queue(@output_plugin_queues[p])
          else
            @logger.warn("Couldn't find output plugin to stop", :plugin => p)
          end
        end

        # Call reload on all existing plugins which are not being dropped
        (@plugins.keys - obsolete_plugins.keys).each(&:reload)
        (@filters - deleted_filters).each(&:reload)

        # Also remove filters
        deleted_filters.each {|f| obsolete_plugins[f] = nil}

        if obsolete_plugins.size > 0
          @logger.info("Stopping removed plugins:", :plugins => obsolete_plugins.keys)
          shutdown_plugins(obsolete_plugins)
        end
        # require 'pry'; binding.pry()

        # Start up filters
        if new_filters.size > 0 || deleted_filters.size > 0
          if new_filters.size > 0
            @logger.info("Starting new filters", :plugins => new_filters)
            new_filters.each do |f|
              f.logger = @logger
              @plugin_setup_mutex.synchronize { f.register }
            end
          end
          @filters = reloaded_filters
          @filterworkers.each_key do |filterworker|
            filterworker.filters = @filters
          end
        end

        if new_inputs.size > 0
          @logger.info("Starting new inputs", :plugins => new_inputs)
          new_inputs.each do |p|
            start_input(p)
          end
        end
        if new_outputs.size > 0
          @logger.info("Starting new outputs", :plugins => new_outputs)
          new_inputs.each do |p|
            start_output(p)
          end
        end

        # Wait for all inputs and outputs to be registered.
        wait_count = new_outputs.size + new_inputs.size
        while wait_count > 0 and @ready_queue.pop
          wait_count -= 1
        end
      rescue Exception => e
        @reloading = false
        raise e
      end
    end
  end

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

    Signal.trap("INT") do
      @logger.warn("SIGINT received, shutting down.")
      shutdown
    end

    Signal.trap("HUP") do
      @logger.warn("SIGHUP received, reloading.")
      reload
    end

    Signal.trap("TERM") do
      @logger.warn("SIGTERM received, shutting down.")
      shutdown
    end
  end # def register_signal_handlers

  private
  def run_input(input, queue)
    LogStash::Util::set_thread_name("<#{input.class.config_name}")
    input.logger = @logger
    @plugin_setup_mutex.synchronize { input.register }
    @logger.info("Input registered", :plugin => input)
    @ready_queue << input
    done = false

    while !done
      begin
        input.run(queue)
        done = true
        input.finished
      rescue => e
        @logger.warn("Input thread exception", :plugin => input,
                     :exception => e, :backtrace => e.backtrace)
        @logger.error("Restarting input due to exception", :plugin => input)
        sleep(1)
        retry # This jumps to the top of the 'begin'
      end
    end

    # The following used to be a warning, but it confused so many users that
    # I disabled it until something better can be provided.
    #@logger.info("Input #{input.to_s} shutting down")

    # If we get here, the plugin finished, check if we need to shutdown.
    shutdown_if_none_running(LogStash::Inputs::Base, queue) unless @reloading
  end # def run_input

  # Run a filter thread
  public
  def run_filter(filterworker, index, output_queue)
    LogStash::Util::set_thread_name("|worker.#{index}")
    filterworker.run
    @logger.warn("Filter worker shutting down", :index => index)

    # If we get here, the plugin finished, check if we need to shutdown.
    shutdown_if_none_running(LogStash::FilterWorker, output_queue) unless @reloading
  end # def run_filter

  # TODO(sissel): Factor this into an 'outputworker'
  def run_output(output, queue)
    LogStash::Util::set_thread_name(">#{output.class.config_name}")
    output.logger = @logger
    @plugin_setup_mutex.synchronize { output.register }
    @logger.info("Output registered", :plugin => output)
    @ready_queue << output

    # TODO(sissel): We need a 'reset' or 'restart' method to call on errors

    begin
      while event = queue.pop do
        @logger.debug? and @logger.debug("Sending event", :target => output)
        output.handle(event)
        break if output.finished?
      end
    rescue Exception => e
      @logger.warn("Output thread exception", :plugin => output,
                   :exception => e, :backtrace => e.backtrace)
      # TODO(sissel): should we abort after too many failures?
      sleep(1)
      retry
    end # begin/rescue

    @logger.warn("Output shutting down", :plugin => output)

    # If we get here, the plugin finished, check if we need to shutdown.
    shutdown_if_none_running(LogStash::Outputs::Base) unless @reloading
  end # def run_output

  def shutdown_if_none_running(pluginclass, queue=nil)
    # Send shutdown signal if all inputs are done.
    @plugins_mutex.synchronize do

      # Look for plugins of type 'pluginclass' (or a subclass)
      # If none are running, start the shutdown sequence and
      # send the 'shutdown' event down the pipeline.
      remaining = @plugins.count do |plugin, thread|
        plugin.is_a?(pluginclass) and plugin.running? and thread.alive?
      end
      @logger.debug? and @logger.debug("Plugins still running",
                                       :type => pluginclass,
                                       :remaining => remaining)

      if remaining == 0
        @logger.warn("All #{pluginclass} finished. Shutting down.")

        # Send 'shutdown' event to other running plugins
        queue << LogStash::SHUTDOWN unless queue.nil?
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
