require "logstash/inputs/base"
require "logstash/namespace"

# This input allows you to receive events over XMPP/Jabber.
#
# This plugin can be used for accepting events from humans or applications
# XMPP, or you can use it for PubSub or general message passing for logstash to
# logstash.
class LogStash::Inputs::Xmpp < LogStash::Inputs::Base
  
  config_name "xmpp"
  plugin_status "beta"

  # The user or resource ID, like foo@example.com.
  config :user, :validate => :string, :required => :true

  # The xmpp password for the user/identity.
  config :password, :validate => :password, :required => :true

  # if muc/multi-user-chat required, give the name of the room that
  # you want to join: room@conference.domain/nick
  config :rooms, :validate => :array

  # The xmpp server to connect to. This is optional. If you omit this setting,
  # the host on the user/identity is used. (foo.com for user@foo.com)
  config :host, :validate => :string

  # Set to true to enable greater debugging in XMPP. Useful for debugging
  # network/authentication erros.
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require 'xmpp4r' # xmpp4r gem
    Jabber::debug = true if @debug

    @client = Jabber::Client.new(Jabber::JID.new(@user))
    @client.connect(@host) # it is ok if host is nil
    @client.auth(@password.value)
    @client.send(Jabber::Presence.new.set_type(:available))

    # load the MUC Client if we are joining rooms.
    require 'xmpp4r/muc/helper/simplemucclient' if @rooms && !@rooms.empty?
  end # def register

  public
  def run(queue)
    if @rooms
      @rooms.each do |room| # handle muc messages in different rooms
        @muc = Jabber::MUC::SimpleMUCClient.new(@client)
        @muc.join(room)
        @muc.on_message do |time,from,body|
          e = to_event(body, "#{room}/#{from}")
          queue << e if e
        end # @muc.on_message
      end # @rooms.each
    end # if @rooms

    @client.add_message_callback do |msg| # handle direct/private messages
      source = "xmpp://#{msg.from.node}@#{msg.from.domain}/#{msg.from.resource}"

      # accept normal msgs (skip presence updates, etc)
      if msg.body != nil
        e = to_event(msg.body, source)
        queue << e
      end
    end # @client.add_message_callback
    sleep
  end # def run

end # def class LogStash:Inputs::Xmpp
