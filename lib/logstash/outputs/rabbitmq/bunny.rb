# encoding: utf-8
class LogStash::Outputs::RabbitMQ
  module BunnyImpl

    #
    # API
    #

    def register
      require "bunny"

      @logger.info("Registering output", :plugin => self)

      connect
      declare_exchange
    end # def register


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
          @x.publish(message, :persistent => @persistent, :routing_key => key)
        else
          @logger.warn("Tried to send a message, but not connected to RabbitMQ yet.")
        end
      rescue Bunny::NetworkFailure, Bunny::ConnectionClosedError, Bunny::ConnectionLevelException, Bunny::TCPConnectionFailed => e
        n = Bunny::Session::DEFAULT_NETWORK_RECOVERY_INTERVAL * 2

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
      @conn.close if @conn && @conn.open?
      @conn = nil

      finished
    end



    #
    # Implementation
    #

    def connect
      @vhost       ||= Bunny::DEFAULT_HOST
      # 5672. Will be switched to 5671 by Bunny if TLS is enabled.
      @port        ||= AMQ::Protocol::DEFAULT_PORT
      @routing_key ||= "#"

      @settings = {
        :vhost => @vhost,
        :host  => @host,
        :port  => @port,
        :automatically_recover => false
      }
      @settings[:user]      = @user || Bunny::DEFAULT_USER
      @settings[:pass]      = if @password
                                @password.value
                              else
                                Bunny::DEFAULT_PASSWORD
                              end

      @settings[:log_level] = if @debug || @logger.debug?
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

      begin
        @conn = Bunny.new(@settings)

        @logger.debug("Connecting to RabbitMQ. Settings: #{@settings.inspect}, queue: #{@queue.inspect}")
        return if terminating?
        @conn.start

        @ch = @conn.create_channel
        @logger.info("Connected to RabbitMQ at #{@settings[:host]}")
      rescue Bunny::NetworkFailure, Bunny::ConnectionClosedError, Bunny::ConnectionLevelException, Bunny::TCPConnectionFailed => e
        n = Bunny::Session::DEFAULT_NETWORK_RECOVERY_INTERVAL * 2

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
  end # BunnyImpl
end # LogStash::Outputs::RabbitMQ
