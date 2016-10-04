require_relative "monitoring_api"

require "childprocess"
require "bundler"
require "tempfile"
require 'yaml'

# A locally started Logstash service
class LogstashService < Service

  LS_VERSION_FILE = File.expand_path(File.join("../../../../", "versions.yml"), __FILE__)
  LS_BIN = "bin/logstash"

  STDIN_CONFIG = "input {stdin {}} output { }"
  RETRY_ATTEMPTS = 10

  @process = nil

  def initialize(settings)
    super("logstash", settings)

    # if you need to point to a LS in different path
    if @settings.is_set?("ls_home_abs_path")
      @logstash_home = @settings.get("ls_home_abs_path")
    else
      # use the LS which was just built in source repo
      ls_version_file = YAML.load_file(LS_VERSION_FILE)
      ls_file = "logstash-" + ls_version_file["logstash"]
      # First try without the snapshot if it's there
      @logstash_home = File.expand_path(File.join("../../../../build", ls_file), __FILE__)
      @logstash_home += "-SNAPSHOT" unless Dir.exists?(@logstash_home)

      puts "Using #{@logstash_home} as LS_HOME"
      @logstash_bin = File.join("#{@logstash_home}", LS_BIN)
      raise "Logstash binary not found in path #{@logstash_home}" unless File.file? @logstash_bin
    end

    @monitoring_api = MonitoringAPI.new
  end

  def alive?
    if @process.nil? || @process.exited?
      raise "Logstash process is not up because of an errot, or it stopped"
    else
      @process.alive?
    end
  end

  # Starts a LS process in background with a given config file
  # and shuts it down after input is completely processed
  def start_background(config_file)
    spawn_logstash("-e", config_file)
  end

  # Given an input this pipes it to LS. Expects a stdin input in LS
  def start_with_input(config, input)
    Bundler.with_clean_env do
      `cat #{input} | #{@logstash_bin} -e \'#{config}\'`
    end
  end

  def start_with_config_string(config)
    spawn_logstash("-e", "#{config} ")
  end

  # Can start LS in stdin and can send messages to stdin
  # Useful to test metrics and such
  def start_with_stdin
    puts "Starting Logstash #{@logstash_bin} -e #{STDIN_CONFIG}"
    Bundler.with_clean_env do
      out = Tempfile.new("duplex")
      out.sync = true
      @process = ChildProcess.build(@logstash_bin, "-e", STDIN_CONFIG)
      # pipe STDOUT and STDERR to a file
      @process.io.stdout = @process.io.stderr = out
      @process.duplex = true
      @process.start
      wait_for_logstash
      puts "Logstash started with PID #{@process.pid}" if alive?
    end
  end

  def write_to_stdin(input)
    if alive?
      @process.io.stdin.puts(input)
    end
  end

  # Spawn LS as a child process
  def spawn_logstash(*args)
    puts "Starting Logstash #{@logstash_bin} #{args}"
    Bundler.with_clean_env do
      @process = ChildProcess.build(@logstash_bin, *args)
      @process.io.inherit!
      @process.start
      wait_for_logstash
      puts "Logstash started with PID #{@process.pid}" if @process.alive?
    end
  end

  def teardown
    if !@process.nil?
      # todo: put this in a sleep-wait loop to kill it force kill
      @process.io.stdin.close rescue nil
      @process.stop
      @process = nil
    end
  end

  # check if LS HTTP port is open
  def is_port_open?
    begin
      s = TCPSocket.open("localhost", 9600)
      s.close
      return true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      return false
    end
  end

  def monitoring_api
    raise "Logstash is not up, but you asked for monitoring API" unless alive?
    @monitoring_api
  end

  # Wait until LS is started by repeatedly doing a socket connection to HTTP port
  def wait_for_logstash
    tries = RETRY_ATTEMPTS
    while tries > 0
      if is_port_open?
        break
      else
        sleep 1
      end
      tries -= 1
    end
  end
  
  # this method only overwrites existing config with new config
  # it does not assume that LS pipeline is fully reloaded after a 
  # config change. It is up to the caller to validate that.
  def reload_config(initial_config_file, reload_config_file)
    FileUtils.cp(reload_config_file, initial_config_file)
  end  
  
  def get_version
    `#{@logstash_bin} --version`
  end
  
  def get_version_yml
    LS_VERSION_FILE
  end   
  
  def process_id
    @process.pid
  end

end
