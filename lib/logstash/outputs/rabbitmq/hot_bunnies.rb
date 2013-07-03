class LogStash::Outputs::RabbitMQ
  module HotBunniesImpl


    #
    # API
    #

    def register
      require "hot_bunnies"
      require "java"

      @logger.info("Registering output", :plugin => self)

      connect
      declare_exchange
    end


    def receive(event)
      return unless output?(event)

      @logger.debug("Sending event", :destination => to_s, :event => event, :key => key)
      key = event.sprintf(@key) if @key

      begin
        publish_serialized(event.to_json, key)
      rescue JSON::GeneratorError => e
        @logger.warn("Trouble converting event to JSON", :exception => e,
                     :event => event)
      end
    end

    def publish_serialized(message, key = @key)
      begin
        if @x
          @x.publish(message, :routing_key => key, :properties => {
            :persistent => @persistent
          })
        else
          @logger.warn("Tried to send a message, but not connected to RabbitMQ yet.")
        end
      rescue HotBunnies::Exception, com.rabbitmq.client.AlreadyClosedException => e
        n = 10

        @logger.error("RabbitMQ connection error: #{e.message}. Will attempt to reconnect in #{n} seconds...",
                      :exception => e,
                      :backtrace => e.backtrace)
        return if terminating?

        sleep n
        retry
      end
    end

    def to_s
      return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@exchange}\##{@key}"
    end

    def teardown
      @conn.close if @conn && @conn.open?
      @conn = nil

      finished
    end



    #
    # Implementation
    #

    def connect
      @vhost       ||= "127.0.0.1"
      # 5672. Will be switched to 5671 by Bunny if TLS is enabled.
      @port        ||= 5672

      @settings = {
        :vhost => @vhost,
        :host  => @host,
        :port  => @port
      }
      @settings[:pass]      = if @password
                                @password.value
                              else
                                "guest"
                              end

      @settings[:log_level] = if @debug
                                :debug
                              else
                                :error
                              end

      @settings[:tls]        = @ssl if @ssl
      proto                  = if @ssl
                                 "amqp"
                               else
                                 "amqps"
                               end
      @connection_url        = "#{proto}://#{@user}@#{@host}:#{@port}#{vhost}/#{@queue}"

      begin
        @conn = HotBunnies.connect(@settings)

        @logger.debug("Connecting to RabbitMQ. Settings: #{@settings.inspect}, queue: #{@queue.inspect}")
        return if terminating?
        @conn.start

        @ch = @conn.create_channel
        @logger.info("Connected to RabbitMQ at #{@settings[:host]}")
      rescue HotBunnies::Exception => e
        n = 10

        @logger.error("RabbitMQ connection error: #{e.message}. Will attempt to reconnect in #{n} seconds...",
                      :exception => e,
                      :backtrace => e.backtrace)
        return if terminating?

        sleep n
        retry
      end
    end

    def declare_exchange
      @logger.debug("Declaring an exchange", :name => @exchange, :type => @exchange_type,
                    :durable => @durable)
      @x = @ch.exchange(@exchange, :type => @exchange_type.to_sym, :durable => @durable)
    end

  end # HotBunniesImpl
end
