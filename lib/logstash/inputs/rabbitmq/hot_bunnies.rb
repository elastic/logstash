class LogStash::Inputs::RabbitMQ
  # HotBunnies-based implementation for JRuby
  module HotBunniesImpl
    def register
      require "hot_bunnies"
      require "java"

      @vhost       ||= "127.0.0.1"
      # 5672. Will be switched to 5671 by Bunny if TLS is enabled.
      @port        ||= 5672
      @routing_key ||= "#"

      @settings = {
        :vhost => @vhost,
        :host  => @host,
        :port  => @port
      }
      @settings[:pass]      = @password.value if @password
      @settings[:tls]       = @ssl if @ssl

      proto                 = if @ssl
                                "amqp"
                              else
                                "amqps"
                              end
      @connection_url       = "#{proto}://#{@user}@#{@host}:#{@port}#{vhost}/#{@queue}"

      @logger.info("Registering input #{@connection_url}")
    end

    def run(output_queue)
      @output_queue          = output_queue
      @break_out_of_the_loop = java.util.concurrent.atomic.AtomicBoolean.new(false)

      # HotBunnies does not raise exceptions when connection goes down with a blocking
      # consumer running (it uses callbacks, as the RabbitMQ Java client does).
      #
      # However, HotBunnies::Channel will make sure to unblock all blocking consumers
      # on any internal shutdown, so #consume will return and another loop iteration
      # will run.
      #
      # This is very similar to how the Bunny implementation works and is sufficient
      # for our needs: it recovers successfully after RabbitMQ is kill -9ed, the
      # network device is shut down, etc. MK.
      until @break_out_of_the_loop.get do
        begin
          setup
          consume
        rescue HotBunnies::Exception, java.lang.Throwable, com.rabbitmq.client.AlreadyClosedException => e
          n = 10
          @logger.error("RabbitMQ connection error: #{e}. Will reconnect in #{n} seconds...")

          sleep n
          retry
        end

        n = 10
        @logger.error("RabbitMQ connection error: #{e}. Will reconnect in #{n} seconds...")
      end
    end

    def teardown
      @break_out_of_the_loop.set(true)

      @consumer.cancel
      @consumer.gracefully_shut_down
      @q.delete unless @durable

      @ch.close         if @ch && @ch.open?
      @connection.close if @connection && @connection.open?

      finished
    end

    #
    # Implementation
    #

    protected

    def setup
      return if terminating?

      @conn = HotBunnies.connect(@settings)
      @logger.info("Connected to RabbitMQ #{@connection_url}")

      @ch          = @conn.create_channel.tap do |ch|
        ch.prefetch = @prefetch_count
      end

      @arguments_hash = Hash[*@arguments]

      @q = @ch.queue(@queue,
                     :durable     => @durable,
                     :auto_delete => @auto_delete,
                     :exclusive   => @exclusive,
                     :arguments   => @arguments_hash)
    end

    def consume
      return if terminating?

      # we manually build a consumer here to be able to keep a reference to it
      # in an @ivar even though we use a blocking version of HB::Queue#subscribe
      @consumer = @q.build_consumer(:block => true) do |metadata, data|
        @codec.decode(data) do |event|
          event["source"] = @connection_url
          @output_queue << event if event
          @ch.ack(metadata.delivery_tag) if @ack
        end
      end
      @q.subscribe_with(@consumer, :manual_ack => @ack, :block => true)
      @logger.info "Past subscribe_with"
    end
  end # HotBunniesImpl
end
