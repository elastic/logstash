require 'rubygems'
require 'lib/net/stats'
require 'lib/net/messagepacket'
require 'uuid'
require 'stomp'

USE_MARSHAL = ENV.has_key?("USE_MARSHAL")

module LogStash; module Net
  # The MessageClient class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageSocket
    MAXBUF = 30

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
      if USE_MARSHAL
        obj = Marshal.load(stompmsg.body)
      else
        obj = JSON::load(stompmsg.body)
        if !obj.is_a?(Array)
          obj = [obj]
        end
      end

      #puts "Got #{obj.length} items"
      obj.each do |item|
        if USE_MARSHAL
          message = item
        else
          message = Message.new_from_data(item)
        end
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

      if @close # set by 'close' method
        @stomp.close
      end
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

      if USE_MARSHAL
        data = Marshal.dump(msgs)
      else
        data = msgs.to_json
      end
      options = {
        "persistent" => true,
        "reply-to" => "/queue/#{@id}",
      }
      #puts "Flushing: #{data[0..40]}..."
      @stomp.send(destination, data, options)
      msgs.clear
    end

    def sendmsg(destination, msg)
      if msg.is_a?(RequestMessage)
        msg.generate_id!
      end
      #puts "Sending to #{destination}: #{msg}"
      @outbuffer[destination] << msg

      if @outbuffer[destination].length > MAXBUF
        flushout(destination)
      end
    end

    def handler=(handler)
      #puts "Setting handler to #{handler.class.name}"
      @handler = handler
    end

    def close
      @close = true
    end
  end # class MessageSocket
end; end # module LogStash::Net
