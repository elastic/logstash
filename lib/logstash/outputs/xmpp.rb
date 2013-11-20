# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# This output allows you ship events over XMPP/Jabber.
#
# This plugin can be used for posting events to humans over XMPP, or you can
# use it for PubSub or general message passing for logstash to logstash.
class LogStash::Outputs::Xmpp < LogStash::Outputs::Base
  config_name "xmpp"
  milestone 2

  # The user or resource ID, like foo@example.com.
  config :user, :validate => :string, :required => :true

  # The xmpp password for the user/identity.
  config :password, :validate => :password, :required => :true

  # The users to send messages to
  config :users, :validate => :array

  # if muc/multi-user-chat required, give the name of the room that
  # you want to join: room@conference.domain/nick
  config :rooms, :validate => :array

  # The xmpp server to connect to. This is optional. If you omit this setting,
  # the host on the user/identity is used. (foo.com for user@foo.com)
  config :host, :validate => :string

  # The message to send. This supports dynamic strings like %{host}
  config :message, :validate => :string, :required => true

  public
  def register
    require "xmpp4r"
    @client = connect

    @mucs = []
    @users = [] if !@users

    # load the MUC Client if we are joining rooms.
    if @rooms && !@rooms.empty?
      require 'xmpp4r/muc'
      @rooms.each do |room| # handle muc messages in different rooms
        muc = Jabber::MUC::MUCClient.new(@client)
        muc.join(room)
        @mucs << muc
      end # @rooms.each
    end # if @rooms
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
    return unless output?(event)

    string_message = event.sprintf(@message)
    @users.each do |user|
      msg = Jabber::Message.new(user, string_message)
      msg.type = :chat
      @client.send(msg)
    end # @targets.each

    msg = Jabber::Message.new(nil, string_message)
    msg.type = :groupchat
    @mucs.each do |muc|
      muc.send(msg)
    end # @mucs.each
  end # def receive
end # class LogStash::Outputs::Xmpp
