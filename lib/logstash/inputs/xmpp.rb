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

  public
    def register
      require 'xmpp4r' # xmpp4r gem
      @cl = Jabber::Client.new(Jabber::JID.new("#{@jid}"))
      @cl.connect
      @cl.auth("#{@pass}")
      @cl.send(Jabber::Presence.new.set_type(:available))
      if @rooms
        require 'xmpp4r/muc/helper/simplemucclient' # xmpp4r muc helper
      end
    end # def register

    def run(queue)
      if @rooms
        @rooms.each do |room| # handle muc messages in different rooms
          @muc = Jabber::MUC::SimpleMUCClient.new(@cl)
          @muc.join("#{room}")
          @muc.on_message { |time,from,body|
            e = to_event(body, "#{room}/#{from}")
            if e
              queue << e
            end
          }
        end
      end 

      @cl.add_message_callback { |msg| # handle direct/private messages
        e = to_event(msg.body, msg.from) unless msg.body == nil # to avoid msgs from presence updates etc. 
        if e 
          queue << e
        end
      }
    end # def run

end # def class LogStash:Inputs::Xmpp

