require "logstash/inputs/base"
require "logstash/namespace"

# TODO(sissel): This class doesn't work yet in JRuby.
# http://jira.codehaus.org/browse/JRUBY-4941

# Stream events from a STOMP broker.
#
# http://stomp.codehaus.org/
class LogStash::Inputs::Stomp < LogStash::Inputs::Base
  config_name "stomp"

  # The address of the STOMP server.
  config :host, :validate => :string, :default => "localhost"

  # The port to connet to on your STOMP server.
  config :port, :validate => :number, :default => 61613

  # The username to authenticate with.
  config :user, :validate => :string, :default => ""

  # The password to authenticate with.
  config :password, :validate => :password, :default => ""

  # The destination to read events from.
  #
  # Example: "/topic/logstash"
  config :destination, :validate => :string, :required => true

  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def initialize(params)
    super

    @format ||= "json_event"
    raise "Stomp input currently not supported. See " +
          "http://jira.codehaus.org/browse/JRUBY-4941 and " +
          "https://logstash.jira.com/browse/LOGSTASH-8"
  end

  public
  def register
    require "stomp"

    @client = Stomp::Client.new(@user, @password.value, @host, @port)
    @stomp_url = "stomp://#{@user}:#{@password}@#{@host}:#{@port}/#{@destination}"
  end # def register

  def run(output_queue)
    @client.subscribe(@destination) do |msg|
      e = to_event(message.body, @stomp_url)
      if e
        output_queue << e
      end
    end

    raise "disconnected from stomp server"
  end # def run
end # class LogStash::Inputs::Stomp
