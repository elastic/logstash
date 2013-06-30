class LogStash::Inputs::RabbitMQ
  # HotBunnies-based implementation for JRuby
  module HotBunniesImpl
    def register
      require "hot_bunnies"

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

    def run(queue)
      begin
        @connection = HotBunnies.connect(@settings)

        @logger.debug("Connecting to RabbitMQ. Settings: #{@settings.inspect}, queue: #{@queue.inspect}")
        return if terminating?

        @ch          = @conn.create_channel.tap do |ch|
          ch.prefetch = @prefetch_count
        end

        @arguments_hash = Hash[*@arguments]

        @q = @ch.queue(@queue,
                       :durable     => @durable,
                       :auto_delete => @auto_delete,
                       :exclusive   => @exclusive,
                       :arguments   => @arguments_hash)
        @q.bind(@exchange, :routing_key => @key)

        # we manually build a consumer here to be able to keep a reference to it
        # in an @ivar even though we use a blocking version of HB::Queue#subscribe
        @consumer = @q.build_consumer(:block => true)
        @q.subscribe_with(@consumer, :manual_ack => @ack, :block => true) do |_, data|
          @codec.decode(data) do |event|
            event["source"] = @connection_url
            queue << event
          end
        end
      rescue HotBunnies::Exception, java.lang.Throwable => e
        @logger.error("RabbitMQ connection error, will reconnect: #{e}")

        sleep 3
        retry
      end
    end

    def teardown
      @consumer.cancel
      @consumer.gracefully_shut_down
      @q.delete unless @durable

      @ch.close         if @ch && @ch.open?
      @connection.close if @connection && @connection.open?

      finished
    end
  end # HotBunniesImpl
end
