require "logstash/outputs/base"
require "logstash/namespace"
require "xmpp4r"

# This output allows you to pull metrics from your logs and ship them to
# XMPP/Jabber.
class LogStash::Outputs::Xmpp< LogStash::Outputs::Base
  config_name "xmpp"

  # Connection information for server
  config :resource, :validate => :string, :required => true
  config :password, :validate => :string, :required => true
  config :targets, :validate => :array, :required => true

  # The message to send. This supports dynamic strings like %{@source_host}
  config :message, :validate => :string, :required => true

  def register
    @client = connect
  end # def register

  def connect
    client = Client.new(JID::new(@resource))
    client.connect
    client.auth(@password)
  end # def connect

  public
  def receive(event)
    t = event.sprintf(@message)
    @targets.each do |target|
      msg = Message::new("#{target}", t)
      msg.type=:chat
      @client.send(msg)
    end
  end # def receive
end # class LogStash::Outputs::Xmpp
