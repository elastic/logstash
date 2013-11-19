# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/event"

# Push messages to the juggernaut websockets server:
#
# * https://github.com/maccman/juggernaut
#
# Wraps Websockets and supports other methods (including xhr longpolling) This
# is basically, just an extension of the redis output (Juggernaut pulls
# messages from redis).  But it pushes messages to a particular channel and
# formats the messages in the way juggernaut expects.
class LogStash::Outputs::Juggernaut < LogStash::Outputs::Base

  config_name "juggernaut"
  milestone 1

  # The hostname of the redis server to which juggernaut is listening.
  config :host, :validate => :string, :default => "127.0.0.1"

  # The port to connect on.
  config :port, :validate => :number, :default => 6379

  # The redis database number.
  config :db, :validate => :number, :default => 0

  # Redis initial connection timeout in seconds.
  config :timeout, :validate => :number, :default => 5

  # Password to authenticate with.  There is no authentication by default.
  config :password, :validate => :password

  # List of channels to which to publish. Dynamic names are
  # valid here, for example "logstash-%{type}".
  config :channels, :validate => :array, :required => true

  # How should the message be formatted before pushing to the websocket.
  config :message_format, :validate => :string

  public
  def register
    require 'redis'

    if not @channels
      raise RuntimeError.new(
        "Must define the channels on which to publish the messages"
      )
    end
    # end TODO

    @redis = nil
  end # def register

  private
  def connect
    Redis.new(
      :host => @host,
      :port => @port,
      :timeout => @timeout,
      :db => @db,
      :password => @password
    )
  end # def connect

  # A string used to identify a redis instance in log messages
  private
  def identity
    @name || "redis://#{@password}@#{@host}:#{@port}/#{@db} #{@data_type}:#{@key}"
  end


  public
  def receive(event)
    return unless output?(event)
    begin
      @redis ||= connect
      if @message_format
        formatted = event.sprintf(@message_format)
      else
        formatted = event.to_json
      end
      juggernaut_message = {
        "channels" => @channels.collect{ |x| event.sprintf(x) },
        "data" => event["message"]
      }

      @redis.publish 'juggernaut', juggernaut_message.to_json
    rescue => e
      @logger.warn("Failed to send event to redis", :event => event,
                   :identity => identity, :exception => e,
                   :backtrace => e.backtrace)
      raise e
    end
  end # def receive

  public
  def teardown
    if @data_type == 'channel' and @redis
      @redis.quit
      @redis = nil
    end
  end

end
