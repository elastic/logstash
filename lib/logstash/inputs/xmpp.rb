require "logstash/inputs/base"
require "logstash/namespace"

class LogStash::Inputs::Xmpp < LogStash::Inputs::Base
  
  config_name "xmpp"

  # user's id: foo@example.com
  config :jid, :validate => :string, :required => :true

  # password
  config :pass, :validate => :string, :required => :true

  # if muc/multi-user-chat required, pass the name of the room: room@conference.domain/nick
  config :rooms, :validate => :array

  # The server to connect to. This is optional. If you omit this setting, the
  # host on the JID is used. (foo.com for user@foo.com)
  config :server, :validate => :string

  # Set to true to enable greater debugging in XMPP. Useful for debugging
  # network/authentication erros.
  config :debug, :validate => :boolean, :default => false

  public
    def register
      require 'xmpp4r' # xmpp4r gem
      Jabber::debug = true if @debug

      @cl = Jabber::Client.new(Jabber::JID.new(@jid))
      @cl.connect(@server) # ok if @server is nill
      @cl.auth(@pass)
      @cl.send(Jabber::Presence.new.set_type(:available))
      if @rooms
        require 'xmpp4r/muc/helper/simplemucclient' # xmpp4r muc helper
      end
    end # def register

    def run(queue)
      if @rooms
        @rooms.each do |room| # handle muc messages in different rooms
          @muc = Jabber::MUC::SimpleMUCClient.new(@cl)
          @muc.join(room)
          @muc.on_message { |time,from,body|
            e = to_event(body, "#{room}/#{from}")
            if e
              queue << e
            end
          }
        end
      end 

      @cl.add_message_callback { |msg| # handle direct/private messages
        source = "xmpp://#{msg.from.node}@#{msg.from.domain}/#{msg.from.resource}"
        # accept normal msgs (skip presence updates, etc)
        e = to_event(msg.body, source) unless msg.body == nil
        if e 
          queue << e
        end
      }
    end # def run

end # def class LogStash:Inputs::Xmpp

