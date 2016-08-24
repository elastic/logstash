require_relative "monitoring_api"

require "childprocess"
require "bundler"
require "tempfile"

# A locally started Logstash service
class Logstash < Service

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
      ls_file = "logstash-" + @settings.get("ls_version")
      ls_file += "-SNAPSHOT" if @settings.get("snapshot")
      @logstash_home = File.expand_path(File.join("../../../../build",ls_file), __FILE__)

      puts "Using #{@logstash_home} as LS_HOME"
      @logstash_bin = File.join("#{@logstash_home}", "bin/logstash")
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
  def spawn_logstash(cli_arg, value)
    puts "Starting Logstash #{@logstash_bin} #{cli_arg} #{value}"
    Bundler.with_clean_env do
      @process = ChildProcess.build(@logstash_bin, cli_arg, value)
      @process.io.inherit!
      @process.start
      wait_for_logstash
      puts "Logstash started with PID #{@process.pid}" if @process.alive?
    end
  end

  def teardown
    if !@process.nil?
      # todo: put this in a sleep-wait loop to kill it force kill
      @process.io.stdin.close
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

end
