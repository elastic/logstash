require 'logstash/inputs/base'
require 'logstash/namespace'

class LogStash::Inputs::Xmpp < LogStash::Inputs::Base

  config_name 'xmpp'
  config :jid, :validate => :string
  config :password, :validate => :string

  public
    def register
      require 'xmpp4r-simple' # xmpp4r-simple gem
    end

  def run(queue)
    # Setup the connection     
    @im = Jabber::Simple.new("#{@jid}", "#{@password}")
    loop do
      # For all messages received, convert 'em to events
      @im.received_messages { |msg|
      e = to_event(msg.body, msg.from)
      if e
        queue << e
      end
    }
    end
  end

end
