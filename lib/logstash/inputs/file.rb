require "logstash/file/manager"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::File < LogStash::Inputs::Base

  @@filemanager = nil
  @@filemanager_lock = Mutex.new

  config_name "file"
  config :path, :required => true

  public
  def register
    # nothing
  end # def register

  public
  def run(queue)
    @@filemanager_lock.synchronize do
      if not @@filemanager
        @@filemanager = LogStash::File::Manager.new(queue)
        @@filemanager.logger = @logger
        @logger.info("Starting #{@@filemanager} thread")
        @@filemanager.run(queue)
      end
    end

    @@filemanager.watch(@path, @config)
  end # def run
end # class LogStash::Inputs::File
