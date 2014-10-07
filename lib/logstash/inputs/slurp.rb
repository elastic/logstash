# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

require "pathname"
require "socket" # for Socket.gethostname

# Slurp an entire file.
#
# By default, each event is assumed to be one line. If you would like
# to join multiple log lines into one event, you'll want to use the
# multiline codec.
class LogStash::Inputs::Slurp < LogStash::Inputs::Base
  config_name "slurp"
  milestone 1

  default :codec, "line"

  # Continue even if an IO error occurs
  config :continue_on_error, :validate => :boolean, :default => false

  # The path(s) to the file(s) to use as an input.
  # You can use globs here, such as `/var/log/*.log`
  # Note that ** causes recursion
  #
  # You may also configure multiple paths. See an example
  # on the [Logstash configuration page](configuration#array).
  config :path, :validate => :array, :required => true

  # Exclusions (matched against the filename, not full path). Globs
  # are valid here, too. For example, if you have
  #
  #     path => "/var/log/*"
  #
  # You might want to exclude gzipped files:
  #
  #     exclude => "*.gz"
  config :exclude, :validate => :array

  public
  def register
    @logger.info("Registering file input", :path => @path)

    @hostname = Socket.gethostname
  end # def register

  public
  def run(queue)
    @path.each do |path|
      Dir.glob(path).each do |file|
        if not is_excluded(file)
          slurp(queue, file)
        end
      end
    end
    finished
  end # def run

  private
  def is_excluded(path)
    if @exclude.nil? or @exclude.empty?
      return false
    end

    basename = Pathname.new(path).basename
    @exclude.each do |exclude_item|
      if File.fnmatch(exclude_item, basename)
        return true
      end
    end
    return false
  end

  def slurp(queue, path)
    @logger.debug? && @logger.debug("Slurping file", :path => path)

    begin
      File.open(path, "r") do |f|
        f.each_line do |line|
          @logger.debug? && @logger.debug("Received line", :path => path, :text => line)
          @codec.decode(line) do |event|
            decorate(event)
            event["host"] = @hostname if !event.include?("host")
            event["path"] = path
            queue << event
          end
        end
      end
    rescue Exception => e
      if @continue_on_error
        @logger.warn("Exception reading file", :path => path, :message => e.message)
      else
        raise
      end
    end

  end
end # class LogStash::Inputs::Slurp
