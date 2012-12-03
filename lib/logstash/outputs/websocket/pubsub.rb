require "logstash/namespace"
require "logstash/outputs/websocket"

class LogStash::Outputs::WebSocket::Pubsub
  attr_accessor :logger

  def initialize
    @subscribers = []
    @subscribers_lock = Mutex.new
  end # def initialize

  def publish(object)
    @subscribers_lock.synchronize do
      break if @subscribers.size == 0

      failed = []
      @subscribers.each do |subscriber|
        begin
          subscriber.call(object)
        rescue => e
          @logger.error("Failed to publish to subscriber", :subscriber => subscriber, :exception => e)
          failed << subscriber
        end
      end

      failed.each do |subscriber|
        @subscribers.delete(subscriber)
      end
    end # @subscribers_lock.synchronize
  end # def Pubsub

  def subscribe(&block)
    queue = Queue.new
    @subscribers_lock.synchronize do
      @subscribers << proc do |event|
        queue << event
      end
    end

    while true
      block.call(queue.pop)
    end
  end # def subscribe
end # class LogStash::Outputs::WebSocket::Pubsub
