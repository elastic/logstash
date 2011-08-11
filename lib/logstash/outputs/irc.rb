require "logstash/outputs/base"
require "logstash/namespace"

# Push events to an AMQP exchange.
#
# AMQP is a messaging system. It requires you to run an AMQP server or 'broker'
# Examples of AMQP servers are [RabbitMQ](http://www.rabbitmq.com/) and 
# [QPid](http://qpid.apache.org/)
class LogStash::Outputs::Irc < LogStash::Outputs::Base
  config_name "irc"

  # Your IRC server address
  config :host, :validate => :string, :required => true

  # The IRC port to connect on
  config :port, :validate => :number, :default => 6667

  # Your irc nickname
  config :nick, :validate => :string, :default => "logstash"

  # Channels to output to
  config :channels, :validate => :array, :required => true

  # Enable or disable debugging
  config :debug, :validate => :boolean, :default => false
  
  # Use event.sprintf to define message structure
  config :structure, :validate => :string, :default => "%{@source}: %{@message}"

  public
  def register
    require "socket"
    @irc = TCPSocket.open(@host,@port)
    @logger.debug(["Connecting to IRC server", @irc.addr.join(":"), @irc.peeraddr.join(":")])
    @irc.puts "USER #{@nick} 0 * #{@nick}"
    @irc.puts "NICK #{@nick}"
    until @irc.eof? do
      m = @irc.gets
      #@logger.debug(m)
      if m.match(".* 001 .*")
        @channels.each do |c|
          @irc.puts "JOIN #{c}"
        end
        break;
      end
    end
  end # def register


  public
  def receive(event)
    m = event.sprintf(@structure)
  
    @channels.each do |c|
      @irc.puts "PRIVMSG #{c} #{m}"
    end
  end

end # class LogStash::Outputs::Amqp
