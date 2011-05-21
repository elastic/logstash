require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname
require "thread" # for Mutex

# Stream events from files.
#
# By default, each event is assumed to be one line. If you
# want to join lines, you'll want to use the multiline filter.
#
# Files are followed in a manner similar to "tail -0F". File rotation
# is detected and handled by this input.
class LogStash::Inputs::File < LogStash::Inputs::Base
  @@filemanager = nil
  @@filemanager_lock = ::Mutex.new

  config_name "file"

  # The path to the file to use as an input.
  # You can use globs here, such as "/var/log/*.log"
  config :path, :validate => :array, :required => true

  # Exclusions. Globs are valid here, too.
  # For example, if you have
  #
  #     path => "/var/log/*"
  #
  # you might want to exclude gzipped files:
  #
  #     exclude => "*.gz"
  config :exclude, :validate => :array

  public
  def register
    require "logstash/file/manager"
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

    @@filemanager.watch(@path, @config, method(:to_event))
  end # def run
end # class LogStash::Inputs::File
