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
      @outbuffer = Hash.new { |h,k| h[k] = [] }
      subscribe(@id)
    end # def initialize

    def subscribe(name)
      #puts "Subscribing to #{name}"
      @stomp.subscribe("/queue/#{name}", @stomp_options) do |stompmsg|
        handle_message(stompmsg)
      end # @stomp.subscribe
    end # def subscribe

    def handle_message(stompmsg)
      obj = JSON::load(stompmsg.body)
      if !obj.is_a?(Array)
        obj = [obj]
      end

      #puts "Got #{obj.length} items"
      obj.each do |item|
        #puts item.inspect
        message = Message.new_from_data(item)
        name = message.class.name.split(":")[-1]
        func = "#{name}Handler"
        #puts stompmsg
        if @handler.respond_to?(func) 
          #puts "Handler found"
          @handler.send(func, message) do |response|
            #puts "response: #{response}"
            sendmsg(stompmsg.headers["reply-to"], response)
          end

          # We should allow the message handler to defer acking if they want
          # For instance, if we want to index things, but only want to ack
          # things once we actually flush to disk.
        else
          $stderr.puts "#{@handler.class.name} does not support #{func}"
        end # if @handler.respond_to?(func)
      end
      @stomp.acknowledge stompmsg
    end # def handle_message

    def run
      @flusher = Thread.new { flusher }
      @stomp.join
    end

    def flusher
      loop do
        #puts @outbuffer.inspect
        @outbuffer.each_key do |destination|
          flushout(destination)
        end
        @outbuffer.clear
        sleep 1
      end
    end

    def flushout(destination)
      msgs = @outbuffer[destination]
      return if msgs.length == 0

      data = msgs.to_json
      options = {
        "persistent" => true,
        "reply-to" => "/queue/#{@id}",
      }
      #puts "Flushing: #{data[0..40]}..."
      @stomp.send(destination, data, options)
      msgs.clear
    end

    def sendmsg(destination, msg)
      #puts "Sending to #{destination}: #{msg}"
      @outbuffer[destination] << msg

      if @outbuffer[destination].length > 10
        flushout(destination)
      end
    end

    def handler=(handler)
      puts "Setting handler to #{handler.class.name}"
      @handler = handler
    end

    def close
      @stomp.close
    end
  end # class MessageSocket
end; end # module LogStash::Net
