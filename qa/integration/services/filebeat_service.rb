# encoding: utf-8
class FilebeatService < Service
  FILEBEAT_CMD = [File.join(File.dirname(__FILE__), "installed", "filebeat", "filebeat"), "-c"]

  class BackgroundProcess
    def initialize(cmd)
      @client_out = Stud::Temporary.file
      @client_out.sync

      @process = ChildProcess.build(*cmd)
      @process.duplex = true
      @process.io.stdout = @process.io.stderr = @client_out
    end

    def start
      @process.start
      sleep(0.1)
      self
    end

    def execution_output
      @client_out.rewind

      # can be used to helper debugging when a test fails
      @execution_output = @client_out.read
    end

    def stop
      begin
        @process.poll_for_exit(5)
      rescue ChildProcess::TimeoutError
        Process.kill("KILL", @process.pid)
      end
    end
  end

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
