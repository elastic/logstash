require "logstash/inputs/base"
require "logstash/namespace"
require "thread"

# Read events from an IRC Server.
#
class LogStash::Inputs::Irc < LogStash::Inputs::Base

  config_name "irc"
  plugin_status "experimental"

  # Host of the IRC Server to connect to.
  config :host, :validate => :string, :required => true

  # Port for the IRC Server
  config :port, :validate => :number, :required => true

  # IRC Nickname
  config :nick, :validate => :string, :default => "logstash"

  # IRC Username
  config :user, :validate => :string, :default => "logstash"

  # IRC Real name
  config :real, :validate => :string, :default => "logstash"

  # IRC Server password
  config :password, :validate => :password

  # Channels to listen to
  config :channels, :validate => :array, :required => true


  def initialize(*args)
    super(*args)
  end # def initialize

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
      c.realname = @real
      c.user = @user
      c.channels = @channels
      c.password = @password
    end
    queue = @irc_queue
    @bot.on :channel  do |m|
      queue << m
    end
  end # def register

  public
  def run(output_queue)
    Thread.new(@bot) do |bot|
      bot.start
    end
    loop do
      msg = @irc_queue.pop
      event = self.to_event(msg.message, "irc://#{@host}:#{@port}/#{msg.channel}")
      event["channel"] = msg.channel
      event["nick"] = msg.user.nick
      output_queue << event
    end
  end # def run
end # class LogStash::Inputs::Irc
