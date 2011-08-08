require "logstash/inputs/base"
require "logstash/namespace"

class LogStash::Inputs::Xmpp < LogStash::Inputs::Base
  
  config_name "xmpp"

  # user's id: foo@example.com
  config :jid, :validate => :string, :required => :true

  # password
  config :pass, :validate => :string, :required => :true

  # if muc/multi-user-chat required, pass the name of the room: room@conference.domain/nick
  config :room, :validate => :string
            
  public
    def register
      require 'xmpp4r'
      @cl = Jabber::Client.new(Jabber::JID.new("#{@jid}"))
      @cl.connect
      @cl.auth("#{@pass}")
      @cl.send(Jabber::Presence.new.set_type(:available))
      if @room
        require 'xmpp4r/muc/helper/simplemucclient'
        @muc = Jabber::MUC::SimpleMUCClient.new(@cl)
        @muc.join("#{@room}")
      end
    end # def register

    def run(queue)
      if @room
        @muc.on_message { |time,from,body|
          e = to_event(body, from)
          if e
            queue << e
          end
        }
      end

      @cl.add_message_callback { |msg|
        e = to_event(msg.body, msg.from) unless msg.body == nil # to avoid msgs from presence updates etc. 
        if e 
          queue << e
        end
      }
    end # def run

end # def class LogStash:Inputs::Xmpp

