require "logstash/outputs/base"
require "logstash/namespace"

# This output allows you to pull metrics from your logs and ship them to
# XMPP/Jabber.
class LogStash::Outputs::Xmpp < LogStash::Outputs::Base
  config_name "xmpp"

  # The user or resource ID, like foo@example.com.
  config :user, :validate => :string, :required => :true

  # The xmpp password for the JID.
  config :password, :validate => :password, :required => :true

  # The targets to send messages to (users, chat rooms, etc)
  config :targets, :validate => :array, :required => true

  # The xmpp server to connect to. This is optional. If you omit this setting,
  # the host on the JID is used. (foo.com for user@foo.com)
  config :host, :validate => :string

  # The message to send. This supports dynamic strings like %{@source_host}
  config :message, :validate => :string, :required => true

  public
  def register
    require "xmpp4r"
    @client = connect
  end # def register

  public
  def connect
    Jabber::debug = true
    client = Jabber::Client.new(Jabber::JID.new(@user))
    client.connect(@host)
    client.auth(@password.value)
    return client
  end # def connect

  public
  def receive(event)
    string_message = event.sprintf(@message)
    @targets.each do |target|
      msg = Jabber::Message.new(target, string_message)
      msg.type = :chat
      @client.send(msg)
    end # @targets.each
  end # def receive
end # class LogStash::Outputs::Xmpp
