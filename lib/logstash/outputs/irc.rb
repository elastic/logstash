require "logstash/outputs/base"
require "logstash/namespace"
require "thread"

# Write events to IRC
#
class LogStash::Outputs::Irc < LogStash::Outputs::Base

  config_name "irc"
  milestone 1

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

  # IRC server password
  config :password, :validate => :password

  # Channels to broadcast to.
  # 
  # These should be full channel names including the '#' symbol, such as
  # "#logstash".
  config :channels, :validate => :array, :required => true

  # Message format to send, event tokens are usable here
  config :format, :validate => :string, :default => "%{@message}"

  # Set this to true to enable SSL.
  config :secure, :validate => :boolean, :default => false

  # Limit the rate of messages sent to IRC in messages per second.
  config :messages_per_second, :validate => :number, :default => 0.5

  public
  def register
    require "cinch"
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
      c.password = @password.value rescue nil
      c.ssl.use = @secure
      c.messages_per_second = @messages_per_second if @messages_per_second
    end
    Thread.new(@bot) do |bot|
      bot.start
    end
  end # def register

  public
  def receive(event)
    return unless output?(event)
    @bot.channels.each do |channel|
      channel.msg(event.sprintf(@format))
    end # channels.each
  end # def receive
end # class LogStash::Outputs::Irc
