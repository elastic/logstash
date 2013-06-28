class LogStash::Inputs::RabbitMQ
  module BunnyImpl
    def register
      require "bunny"

      @vhost       ||= Bunny::DEFAULT_HOST
      # 5672. Will be switched to 5671 by Bunny if TLS is enabled.
      @port        ||= AMQ::Protocol::DEFAULT_PORT
      @routing_key ||= "#"

      @settings = {
        :vhost => @vhost,
        :host  => @host,
        :port  => @port
      }
      @settings[:user]      = @user || Bunny::DEFAULT_USER
      @settings[:pass]      = if @password
                                @password.value
                              else
                                Bunny::DEFAULT_PASSWORD
                              end

      @settings[:log_level] = if @debug
                                :debug
                              else
                                :error
                              end

      @settings[:tls]        = @ssl if @ssl
      @settings[:verify_ssl] = @verify_ssl if @verify_ssl

      proto                  = if @ssl
                                 "amqp"
                               else
                                 "amqps"
                               end
      @connection_url        = "#{proto}://#{@user}@#{@host}:#{@port}#{vhost}/#{@queue}"

      @logger.info("Registering input #{@connection_url}")
    end

    def run(queue)
      begin
        @connection = Bunny.new(@settings)

        @logger.debug("Connecting to RabbitMQ. Settings: #{@settings.inspect}, queue: #{@queue.inspect}")
        return if terminating?
        @conn.start

        @ch = @conn.create_channel

        @ch.prefetch(@prefetch_count)

        @arguments_hash = Hash[*@arguments]

        @q = @ch.queue(@queue,
                       :durable     => @durable,
                       :auto_delete => @auto_delete,
                       :exclusive   => @exclusive,
                       :arguments   => @arguments_hash)
        @q.bind(@exchange, :routing_key => @key)

        @consumer = @q.subscribe(:manual_ack => @ack) do |delivery_info, properties, data|
          @codec.decode(data) do |event|
            event["source"] = @connection_url
            queue << event
          end
        end
      rescue Bunny::NetworkFailure, Bunny::ConnectionClosedError, Bunny::ConnectionLevelException => e
        @logger.error("RabbitMQ connection error, will reconnect: #{e}")

        n = Bunny::DEFAULT_NETWORK_RECOVERY_INTERVAL / 2

        sleep n
        retry
      end
    end

    def teardown
      @consumer.cancel
      @q.delete unless @durable

      @ch.close         if @ch && @ch.open?
      @connection.close if @connection && @connection.open?

      finished
    end
  end # BunnyImpl
end
