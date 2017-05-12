# encoding: utf-8
require_relative './helpers'

class FilebeatService < Service
  FILEBEAT_CMD = [File.join(File.dirname(__FILE__), "installed", "filebeat", "filebeat"), "-c"]

  def initialize(settings)
    super("filebeat", settings)
  end

  def run(config_path)
    cmd = FILEBEAT_CMD.dup << config_path
    puts "Starting Filebeat with #{cmd.join(" ")}"
    @process = BackgroundProcess.new(cmd).start
  end

  def stop
    @process.stop
  end
end
