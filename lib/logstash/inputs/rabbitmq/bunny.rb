# encoding: utf-8
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

      @logger.info("Registering input #{@connection_url}")
    end

    def run(output_queue)
      @output_queue = output_queue

      begin
        setup
        consume
      rescue Bunny::NetworkFailure, Bunny::ConnectionClosedError, Bunny::ConnectionLevelException, Bunny::TCPConnectionFailed => e
        n = Bunny::Session::DEFAULT_NETWORK_RECOVERY_INTERVAL * 2

        # Because we manually reconnect instead of letting Bunny
        # handle failures,
        # make sure we don't leave any consumer work pool
        # threads behind. MK.
        @ch.maybe_kill_consumer_work_pool!
        @logger.error("RabbitMQ connection error: #{e.message}. Will attempt to reconnect in #{n} seconds...")

        sleep n
        retry
      end
    end

    def teardown
      @consumer.cancel
      @q.delete unless @durable

      @ch.close   if @ch && @ch.open?
      @conn.close if @conn && @conn.open?

      finished
    end

    def setup
      @conn = Bunny.new(@settings)

      @logger.debug("Connecting to RabbitMQ. Settings: #{@settings.inspect}, queue: #{@queue.inspect}")
      return if terminating?
      @conn.start

      @ch = @conn.create_channel.tap do |ch|
        ch.prefetch(@prefetch_count)
      end
      @logger.info("Connected to RabbitMQ at #{@settings[:host]}")

      @arguments_hash = Hash[*@arguments]

      @q = @ch.queue(@queue,
                     :durable     => @durable,
                     :auto_delete => @auto_delete,
                     :exclusive   => @exclusive,
                     :passive     => @passive,
                     :arguments   => @arguments)

      # exchange binding is optional for the input
      if @exchange
        @q.bind(@exchange, :routing_key => @key)
      end
    end

    def consume
      @logger.info("Will consume events from queue #{@q.name}")

      # we both need to block the caller in Bunny::Queue#subscribe and have
      # a reference to the consumer so that we can cancel it, so
      # a consumer manually. MK.
      @consumer = Bunny::Consumer.new(@ch, @q)
      @q.subscribe(:manual_ack => @ack, :block => true) do |delivery_info, properties, data|
        @codec.decode(data) do |event|
          decorate(event)
          @output_queue << event
        end

        @ch.acknowledge(delivery_info.delivery_tag) if @ack
      end
    end
  end # BunnyImpl
end
