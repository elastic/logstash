# encoding: utf-8
class LogStash::Outputs::RabbitMQ
  module MarchHareImpl


    #
    # API
    #

    def register
      require "march_hare"
      require "java"

      @logger.info("Registering output", :plugin => self)

      @connected = java.util.concurrent.atomic.AtomicBoolean.new

      connect
      declare_exchange

      @connected.set(true)

      @codec.on_event(&method(:publish_serialized))
    end


    def receive(event)
      return unless output?(event)

      begin
        @codec.encode(event)
      rescue JSON::GeneratorError => e
        @logger.warn("Trouble converting event to JSON", :exception => e,
                     :event => event)
      end
    end

    def publish_serialized(message)
      begin
        if @connected.get
          @x.publish(message, :routing_key => @key, :properties => {
            :persistent => @persistent
          })
        else
          @logger.warn("Tried to send a message, but not connected to RabbitMQ.")
        end
      rescue MarchHare::Exception, com.rabbitmq.client.AlreadyClosedException => e
        @connected.set(false)
        n = 10

        @logger.error("RabbitMQ connection error: #{e.message}. Will attempt to reconnect in #{n} seconds...",
                      :exception => e,
                      :backtrace => e.backtrace)
        return if terminating?

        sleep n

        connect
        declare_exchange
        retry
      end
    end

    def to_s
      return "amqp://#{@user}@#{@host}:#{@port}#{@vhost}/#{@exchange_type}/#{@exchange}\##{@key}"
    end

    def teardown
      @connected.set(false)
      @conn.close if @conn && @conn.open?
      @conn = nil

      finished
    end



    #
    # Implementation
    #

    def connect
      return if terminating?

      @vhost       ||= "127.0.0.1"
      # 5672. Will be switched to 5671 by Bunny if TLS is enabled.
      @port        ||= 5672

      @settings = {
        :vhost => @vhost,
        :host  => @host,
        :port  => @port,
        :user  => @user,
        :automatic_recovery => false
      }
      @settings[:pass]      = if @password
                                @password.value
                              else
                                "guest"
                              end

      @settings[:tls]        = @ssl if @ssl
      proto                  = if @ssl
                                 "amqp"
                               else
                                 "amqps"
                               end
      @connection_url        = "#{proto}://#{@user}@#{@host}:#{@port}#{vhost}/#{@queue}"

      begin
        @conn = MarchHare.connect(@settings)

        @logger.debug("Connecting to RabbitMQ. Settings: #{@settings.inspect}, queue: #{@queue.inspect}")

        @ch = @conn.create_channel
        @logger.info("Connected to RabbitMQ at #{@settings[:host]}")
      rescue MarchHare::Exception => e
        @connected.set(false)
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

      # sets @connected to true during recovery. MK.
      @connected.set(true)

      @x
    end

  end # MarchHareImpl
end
