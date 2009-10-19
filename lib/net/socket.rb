require 'rubygems'
require 'amqp'
require 'lib/net/messagepacket'
require 'mq'
require 'uuid'

USE_MARSHAL = ENV.has_key?("USE_MARSHAL")


module LogStash; module Net

  class Operation
    def initialize(callback)
      @mutex = Mutex.new
      @callback = callback
      @cv = ConditionVariable.new
    end # def initialize

    def call(*args)
      @mutex.synchronize do
        ret = @callback.call(*args)
        if ret == :finished
          @cv.signal
        end
      end
    end # def call

    def wait_until_finished
      @mutex.synchronize do
        @cv.wait(@mutex)
      end
    end # def wait_until_finished
  end # def Operation

  # The MessageClient class exists only as an alias
  # to the MessageSocketMux. You should use the
  # client class if you are implementing a client.
  class MessageSocket
    MAXBUF = 30

    def initialize(username='', password='', host='localhost', port=61613)
      @id = UUID::generate
      @want_queues = []
      @queues = []
      @want_topics = []
      @topics = []
      @handler = self
      @outbuffer = Hash.new { |h,k| h[k] = [] }
      @mq = nil
      @message_operations = Hash.new
      start_amqp
    end # def initialize

    def start_amqp
      @amqpthread = Thread.new do 
        # Create connection to AMQP, and in turn, the main EventMachine loop.
        AMQP.start(:host => "localhost") do
          @mq = MQ.new
          mq_q = @mq.queue(@id, :auto_delete => true)
          mq_q.subscribe(:ack =>true) { |hdr, msg| handle_message(hdr, msg) }
          handle_new_subscriptions
          
          EM.add_periodic_timer(5) { handle_new_subscriptions }
          EM.add_periodic_timer(1) do
            @outbuffer.each_key { |dest| flushout(dest) }
            @outbuffer.clear
          end
        end # AMQP.start
      end
    end # def start_amqp

    def subscribe(name)
      @want_queues << name 
    end # def subscribe

    def subscribe_topic(name)
      @want_topics << name 
    end # def subscribe_topic

    def handle_message(hdr, msg_body)
      if USE_MARSHAL
        obj = Marshal.load(msg_body)
      else
        obj = JSON::load(msg_body)
        if !obj.is_a?(Array)
          obj = [obj]
        end
      end

      obj.each do |item|
        if USE_MARSHAL
          message = item
        else
          message = Message.new_from_data(item)
        end
        name = message.class.name.split(":")[-1]
        func = "#{name}Handler"

        if @message_operations.has_key?(message.id)
          operation = @message_operations[message.id]
          operation.call message
        elsif @handler.respond_to?(func) 
          @handler.send(func, message) do |response|
            reply = message.replyto
            sendmsg(reply, response)
          end

          # We should allow the message handler to defer acking if they want
          # For instance, if we want to index things, but only want to ack
          # things once we actually flush to disk.
        else
          $stderr.puts "#{@handler.class.name} does not support #{func}"
        end # if @handler.respond_to?(func)
      end
      hdr.ack

      if @close # set by 'close' method
        EM.stop_event_loop
      end
    end # def handle_message

    def run
      @amqpthread.join
    end # run

    def handle_new_subscriptions
      todo = @want_queues - @queues
      todo.each do |queue|
        puts "Subscribing to queue #{queue}"
        mq_q = @mq.queue(queue)
        mq_q.subscribe(:ack =>true) { |hdr, msg| handle_message(hdr, msg) }
        @queues << queue
      end # todo.each

      todo = @want_topics - @topics
      todo.each do |topic|
        puts "Subscribing to topic #{topic}"
        exchange = @mq.topic("amq.topic")
        mq_q = @mq.queue("#{@id}-#{topic}",
                         :exclusive => true,
                         :auto_delete => true).bind(exchange, :key => topic)
        mq_q.subscribe { |hdr, msg| handle_message(hdr, msg) }
        @topics << topic
      end # todo.each
    end # handle_new_subscriptions

    def flushout(destination)
      return unless @mq    # wait until we are connected

      msgs = @outbuffer[destination]
      return if msgs.length == 0

      if USE_MARSHAL
        data = Marshal.dump(msgs)
      else
        data = msgs.to_json
      end
      @mq.queue(destination).publish(data, :persistent => true)
      msgs.clear
    end

    def sendmsg_topic(key, msg)
      return unless @mq    # wait until we are connected
      if (msg.is_a?(RequestMessage) and msg.id == nil)
        msg.generate_id!
      end

      if USE_MARSHAL
        data = Marshal.dump(msg)
      else
        data = msg.to_json
      end

      @mq.topic("amq.topic").publish(data, :key => key)
    end

    def sendmsg(destination, msg, &callback)
      if (msg.is_a?(RequestMessage) and msg.id == nil)
        msg.generate_id!
      end
      msg.replyto = @id
      @outbuffer[destination] << msg
      if @outbuffer[destination].length > MAXBUF
        flushout(destination)
      end

      if block_given?
        op = Operation.new(callback)
        @message_operations[msg.id] = op
        return op
      end
    end

    def handler=(handler)
      @handler = handler
    end

    def close
      @close = true
    end
  end # class MessageSocket
end; end # module LogStash::Net
