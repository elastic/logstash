require 'rubygems'
require 'amqp'
require 'lib/net/messagepacket'
require 'lib/util'
require 'mq'
require 'uuid'
require 'thread'

# http://github.com/tmm1/amqp/issues/#issue/3
# This is our (lame) hack to at least notify the user that something is
# wrong.
module AMQP
  module Client
    alias :original_reconnect :reconnect 
    def reconnect(*args)
      $logger.warn "reconnecting to broker (bad MQ settings?)"

      # some rate limiting
      sleep(5)

      original_reconnect(*args)
    end
  end
end

module LogStash; module Net

  # A single message operation
  # * Takes a callback to call when a message is received
  # * Allows you to wait for the operation to complete.
  # * An operation is 'complete' when the callback returns :finished
  class Operation
    def initialize(callback)
      @mutex = Mutex.new
      @callback = callback
      @cv = ConditionVariable.new
      @finished = false
    end # def initialize

    def call(*args)
      @mutex.synchronize do
        ret = @callback.call(*args)
        if ret == :finished
          @finished = true
          @cv.signal
        else
          return ret
        end
      end
    end # def call

    def wait_until_finished
      @mutex.synchronize do
        @cv.wait(@mutex) if !finished?
      end
    end # def wait_until_finished

    def finished?
      return @finished
    end
  end # def Operation

  # TODO: document this class
  class MessageSocket
    MAXBUF = 20

    def initialize(config, logger)
      @id = UUID::generate
      @config, @logger = config, logger
      @want_queues = []
      @queues = []
      @want_topics = []
      @topics = []
      @handler = self
      @receive_queue = Queue.new
      @outbuffer = Hash.new { |h,k| h[k] = [] }
      #@slidingwindow = LogStash::SlidingWindowSet.new
      @mq = nil
      @message_operations = Hash.new
      @startuplock = Mutex.new

      @mutex = Mutex.new
      @cv = ConditionVariable.new
      start_amqp(@mutex, @cv)
      @mutex.synchronize do
        @logger.debug "Waiting for @mq ..."
        @cv.wait(@mutex)
      end

      start_receiver
    end # def initialize

    def start_amqp(mutex, condvar)
      @amqpthread = Thread.new do 
        # Create connection to AMQP, and in turn, the main EventMachine loop.
        amqp_config = {:host => @config.mqhost,
                       :port => @config.mqport,
                       :user => @config.mquser,
                       :pass => @config.mqpass,
                       :vhost => @config.mqvhost,
                      }
        AMQP.start(amqp_config) do
          mutex.synchronize do
            @mq = MQ.new
            # Notify the main calling thread (MessageSocket#initialize) that
            # we can continue
            condvar.signal
          end

          @logger.info "Subscribing to main queue #{@id}"
          mq_q = @mq.queue(@id, :auto_delete => true)
          #mq_q.subscribe(:ack =>true) { |hdr, msg| handle_message(hdr, msg) }
          mq_q.subscribe(:ack =>true) { |hdr, msg| @receive_queue << [hdr, msg] }
          handle_new_subscriptions
          
          EM.add_periodic_timer(5) { handle_new_subscriptions }
          EM.add_periodic_timer(1) do
            @outbuffer.each_key { |dest| flushout(dest) }
            @outbuffer.clear
          end
        end # AMQP.start
      end
    end # def start_amqp

    def start_receiver
      Thread.new do 
        while true
          header, message = @receive_queue.pop
          handle_message(header, message)
        end
      end
    end # def start_receiver

    def subscribe(name)
      @want_queues << name 
    end # def subscribe

    def subscribe_topic(name)
      @want_topics << name 
    end # def subscribe_topic

    def handle_message(hdr, msg_body)
      obj = JSON::load(msg_body)
      if !obj.is_a?(Array)
        obj = [obj]
      end

      obj.each do |item|
        message = Message.new_from_data(item)
        #if @slidingwindow.include?(message.id)
          #puts "Removing ack for #{message.id}"
          #@slidingwindow.delete(message.id)
        #end
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
        @logger.info "Subscribing to queue #{queue}"
        mq_q = @mq.queue(queue, :durable => true)
        mq_q.subscribe(:ack => true) { |hdr, msg| @receive_queue << [hdr, msg] }
        @queues << queue
      end # todo.each

      todo = @want_topics - @topics
      todo.each do |topic|
        @logger.info "Subscribing to topic #{topic}"
        exchange = @mq.topic("amq.topic")
        mq_q = @mq.queue("#{@id}-#{topic}",
                         :exclusive => true,
                         :auto_delete => true).bind(exchange, :key => topic)
        mq_q.subscribe { |hdr, msg| @receive_queue << [hdr, msg] }
        @topics << topic
      end # todo.each
    end # handle_new_subscriptions

    def flushout(destination)
      return unless @mq    # wait until we are connected

      msgs = @outbuffer[destination]
      return if msgs.length == 0
      data = msgs.to_json
      @mq.queue(destination, :durable => true).publish(data, :persistent => true)
      msgs.clear
    end

    def sendmsg_topic(key, msg)
      return unless @mq    # wait until we are connected
      if (msg.is_a?(RequestMessage) and msg.id == nil)
        msg.generate_id!
      end
      msg.timestamp = Time.now.to_f

      data = msg.to_json
      @mq.topic("amq.topic").publish(data, :key => key)
    end

    def sendmsg(destination, msg, &callback)
      return unless @mq    # wait until we are connected
      if (msg.is_a?(RequestMessage) and msg.id == nil)
        msg.generate_id!
      end
      msg.timestamp = Time.now.to_f
      msg.replyto = @id

      if (msg.is_a?(RequestMessage) and !msg.is_a?(ResponseMessage))
        @logger.info "Tracking #{msg.class.name}##{msg.id}"
        #@slidingwindow << msg.id
      end

      if msg.buffer?
        @outbuffer[destination] << msg
        if @outbuffer[destination].length > MAXBUF
          flushout(destination)
        end
      else
        @mq.queue(destination, :durable => true).publish([msg].to_json, :persistent => true)
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
