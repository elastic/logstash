require 'rubygems'
require 'lib/net/stats'
require 'lib/net/messagepacket'
#require 'eventmachine'
require 'uuid'
require 'stomp'

module LogStash; module Net
  # The MessageClient class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageSocket

    def initialize(username='', password='', host='localhost', port=61613)
      @stomp = Stomp::Client.new(login=username, passcode=password,
                                 host=host, port=port, reliable=true)
      @id = UUID::generate
      @stomp_options = {
        "persistent" => true,
        "client-id" => @id,
        "ack" => "client", # require us to explicitly ack messages
      }

      @handler = self
      subscribe(@id)
    end # def initialize

    def subscribe(name)
      puts "Subscribing to #{name}"
      @stomp.subscribe("/queue/#{name}", @stomp_options) do |stompmsg|
        obj = JSON::load(stompmsg.body)
        message = Message.new_from_data(obj)
        name = message.class.name.split(":")[-1]
        func = "#{name}Handler"
        puts stompmsg
        if @handler.respond_to?(func) 
          puts "Handler found"
          @handler.send(func, message) do |response|
            puts "response: #{response}"
            sendmsg(stompmsg.headers["reply-to"], response)
          end

          # We should allow the message handler to defer acking if they want
          # For instance, if we want to index things, but only want to ack
          # things once we actually flush to disk.
          puts "Acking message: #{stompmsg}"
          begin
            @stomp.acknowledge stompmsg
          rescue => e
            puts e.inspect
            raise e
          end
          puts "Ack done"
        else
          $stderr.puts "#{@handler.class.name} does not support #{func}"
        end # if @handler.respond_to?(func)
      end # @stomp.subscribe
    end # def subscribe

    def run
      @stomp.join
    end

    def sendmsg(destination, msg)
      data = msg.to_json
      options = {
        "persistent" => true,
        "reply-to" => "/queue/#{@id}",
        #"ack" => "client",
      }
      @stomp.send(destination, data, options)
    end

    def handler=(handler)
      @handler = handler
    end
  end # class MessageSocket
end; end # module LogStash::Net
