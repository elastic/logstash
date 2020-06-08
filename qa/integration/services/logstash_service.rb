# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative "monitoring_api"

require "childprocess"
require_relative "../patch/childprocess-modern-java"
require "bundler"
require "socket"
require "tempfile"
require 'yaml'

# A locally started Logstash service
class LogstashService < Service

  LS_ROOT_DIR = File.join("..", "..", "..", "..")
  LS_VERSION_FILE = File.expand_path(File.join(LS_ROOT_DIR, "versions.yml"), __FILE__)
  LS_BUILD_DIR = File.join(LS_ROOT_DIR, "build")
  LS_BIN = File.join("bin", "logstash")
  LS_CONFIG_FILE = File.join("config", "logstash.yml")
  SETTINGS_CLI_FLAG = "--path.settings"

  STDIN_CONFIG = "input {stdin {}} output { }"
  RETRY_ATTEMPTS = 60

  TIMEOUT_MAXIMUM = 60 * 10 # 10mins.

  class ProcessStatus < Struct.new(:exit_code, :stderr_and_stdout); end

  @process = nil

  attr_reader :logstash_home
  attr_reader :default_settings_file
  attr_writer :env_variables

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
      @logstash_home = File.expand_path(File.join(LS_BUILD_DIR, ls_file), __FILE__)
      @logstash_home += "-SNAPSHOT" unless Dir.exist?(@logstash_home)

      puts "Using #{@logstash_home} as LS_HOME"
      @logstash_bin = File.join("#{@logstash_home}", LS_BIN)
      raise "Logstash binary not found in path #{@logstash_home}" unless File.file? @logstash_bin
    end

    @default_settings_file = File.join(@logstash_home, LS_CONFIG_FILE)
    @monitoring_api = MonitoringAPI.new
  end

  def alive?
    if @process.nil? || @process.exited?
      raise "Logstash process is not up because of an error, or it stopped"
    else
      @process.alive?
    end
  end

  def exited?
    @process.exited?
  end

  def exit_code
    @process.exit_code
  end

  # Starts a LS process in background with a given config file
  # and shuts it down after input is completely processed
  def start_background(config_file)
    spawn_logstash("-e", config_file)
  end

  # Given an input this pipes it to LS. Expects a stdin input in LS
  def start_with_input(config, input)
    Bundler.with_clean_env do
      `cat #{Shellwords.escape(input)} | #{Shellwords.escape(@logstash_bin)} -e \'#{config}\'`
    end
  end

  def start_background_with_config_settings(config, settings_file)
    spawn_logstash("-f", "#{config}", "--path.settings", settings_file)
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
      @process = build_child_process("-e", STDIN_CONFIG)
      # pipe STDOUT and STDERR to a file
      @process.io.stdout = @process.io.stderr = out
      @process.duplex = true
      java_home = java.lang.System.getProperty('java.home')
      @process.environment['JAVA_HOME'] = java_home
      @process.start
      wait_for_logstash
      puts "Logstash started with PID #{@process.pid}, JAVA_HOME: #{java_home}" if alive?
    end
  end

  def write_to_stdin(input)
    if alive?
      @process.io.stdin.puts(input)
    end
  end

  # Spawn LS as a child process
  def spawn_logstash(*args)
    Bundler.with_clean_env do
      @process = build_child_process(*args)
      @env_variables.map { |k, v|  @process.environment[k] = v} unless @env_variables.nil?
      java_home = java.lang.System.getProperty('java.home')
      @process.environment['JAVA_HOME'] = java_home
      @process.io.inherit!
      @process.start
      puts "Logstash started with PID #{@process.pid}, JAVA_HOME: #{java_home}" if @process.alive?
    end
  end

  def build_child_process(*args)
    feature_config_dir = @settings.feature_config_dir
    # if we are using a feature flag and special settings dir to enable it, use it
    # If some tests is explicitly using --path.settings, ignore doing this, because the tests
    # chose to overwrite it.
    if feature_config_dir && !args.include?(SETTINGS_CLI_FLAG)
      args << "--path.settings"
      args << feature_config_dir
      puts "Found feature flag. Starting LS using --path.settings #{feature_config_dir}"
    end
    puts "Starting Logstash: #{@logstash_bin} #{args}"
    ChildProcess.build(@logstash_bin, *args)
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
        return
      else
        sleep 1
      end
      tries -= 1
    end
    raise "Logstash REST API did not come up after #{RETRY_ATTEMPTS}s."
  end

  # this method only overwrites existing config with new config
  # it does not assume that LS pipeline is fully reloaded after a
  # config change. It is up to the caller to validate that.
  def reload_config(initial_config_file, reload_config_file)
    FileUtils.cp(reload_config_file, initial_config_file)
  end

  def get_version
    `#{Shellwords.escape(@logstash_bin)} --version`.split("\n").last
  end

  def get_version_yml
    LS_VERSION_FILE
  end

  def process_id
    @process.pid
  end

  def application_settings_file
    feature_config_dir = @settings.feature_config_dir
    unless feature_config_dir
      @default_settings_file
    else
      File.join(feature_config_dir, "logstash.yml")
    end
  end

  def plugin_cli
    PluginCli.new(self)
  end

  def lock_file
    File.join(@logstash_home, "Gemfile.lock")
  end

  def run_cmd(cmd_args, change_dir = true, environment = {})
    out = Tempfile.new("content")
    out.sync = true

    cmd, *args = cmd_args
    process = ChildProcess.build(cmd, *args)
    environment.each do |k, v|
      process.environment[k] = v
    end
    process.io.stdout = process.io.stderr = out

    Bundler.with_clean_env do
      if change_dir
        Dir.chdir(@logstash_home) do
          process.start
        end
      else
        process.start
      end
    end

    process.poll_for_exit(TIMEOUT_MAXIMUM)
    out.rewind
    ProcessStatus.new(process.exit_code, out.read)
  end

  def run(*args)
    run_cmd [ @logstash_bin, *args ]
  end

  class PluginCli

    LOGSTASH_PLUGIN = File.join("bin", "logstash-plugin")

    attr_reader :logstash_plugin

    def initialize(logstash_service)
      @logstash = logstash_service
      @logstash_plugin = File.join(@logstash.logstash_home, LOGSTASH_PLUGIN)
    end

    def remove(plugin_name)
      run("remove #{plugin_name}")
    end

    def prepare_offline_pack(plugins, output_zip = nil)
      plugins = Array(plugins)

      if output_zip.nil?
        run("prepare-offline-pack #{plugins.join(" ")}")
      else
        run("prepare-offline-pack --output #{output_zip} #{plugins.join(" ")}")
      end
    end

    def list(plugin_name, verbose = false)
      run("list #{plugin_name} #{verbose ? "--verbose" : ""}")
    end

    def install(plugin_name)
      run("install #{plugin_name}")
    end

    def run(command)
      run_raw("#{logstash_plugin} #{command}")
    end

    def run_raw(cmd, change_dir = true, environment = {})
      @logstash.run_cmd(cmd.split(' '), change_dir, environment)
    end
  end
end
