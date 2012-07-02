require "logstash/outputs/base"
require "logstash/namespace"
require "thread"
require "cinch"

# Write events to IRC
#
class LogStash::Outputs::Irc < LogStash::Outputs::Base

  config_name "irc"
  plugin_status "experimental"

  # Address of the host to connect to
  config :host, :validate => :string, :required => true

  # Port on host to connect to.
  config :port, :validate => :number, :required => true

  # IRC Nickname
  config :nick, :validate => :string, :default => "logstash"

  # IRC Username
  config :user, :validate => :string, :default => "logstash"

  # IRC Real name
  config :real, :validate => :string, :default => "logstash"

  # Channels to broadcast to
  config :channels, :validate => :array, :required => true

  # Message format to send, event tokens are usable here
  config :format, :validate => :string, :default => "%{@message}"

  public
  def register
    @irc_queue = Queue.new
    @logger.info("Connecting to irc server", :host => @host, :port => @port, :nick => @nick, :channels => @channels)

    @bot = Cinch::Bot.new
    @bot.loggers.clear
    @bot.configure do |c|
      c.server = @host
      c.port = @port
      c.nick = @nick
      c.user = @user
      c.realname = @real
      c.channels = @channels
      c.channels = @channels
      c.channels = @channels
      c.password = @password
    end
    Thread.new(@bot) do |bot|
      bot.start
    end
  end # def register

  public
  def receive(event)
    @bot.channels.each do |channel|
      channel.msg(event.sprintf(@format))
    end # channels.each
  end # def receive
end # class LogStash::Outputs::Irc
