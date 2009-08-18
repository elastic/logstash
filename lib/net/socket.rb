require 'rubygems'
require 'lib/net/messagepacket'
require 'eventmachine'

module LogStash; module Net
  # The MessageClient class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageSocket < EventMachine::Connection
    # connection init callback from EventMachine::Connection
    def post_init
      #set_comm_inactivity_timeout(30)
      @buffer = ""
    end

    # data receiver callback from EventMachine::Connection
    def receive_data(data)
      @buffer += data

      len = 0
      count = 0
      MessagePacket.each(@buffer) do |packet|
        len += packet.length
        count += 1
        obj = JSON::load(packet.content)
        msg = Message.new_from_data(obj)

        if !@handler
          $stderr.puts "No message handler set. Can't handle #{msg.class.name}"
          next
        end

        name = msg.class.name.split(":")[-1]
        func = "#{name}Handler"
        if @handler.respond_to?(func):
          #operation = lambda do 
            #@handler.send(func, msg) do |response|
              #sendmsg(response)
            #end
          #end
          #EventMachine.defer(operation, nil)
          
          # We actually get better performance if we don't defer processing
          # to another thread. This should be done carefully, though, as
          # blocking here will block the receiving thread for this socket
          # (maybe for all of eventmachine?).
          @handler.send(func, msg) do |response|
            sendmsg(response)
          end
        else
          $stderr.puts "#{@handler.class.name} does not support #{func}"
        end
      end

      if len > 0
        puts "Removing #{len} bytes (#{count} packets)"
        @buffer[0 .. len - 1] = ""
      end
    end # def receive_data

    def sendmsg(msg)
      if msg.is_a?(RequestMessage) and msg.id == nil
        msg.generate_id!
      end

      data = msg.to_json
      packet = MessagePacket.new(data)
      #puts "Sending: #{packet.encode.inspect}"
      send_data(packet.encode)
    end

    def handler=(obj)
      @handler = obj
    end
  end # class MessageSocket
end; end # module LogStash::Net
