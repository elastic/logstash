require 'logstash/namespace'

module LogStash::Util::AMQP

  def select_driver
    case RUBY_ENGINE
    when 'jruby'
      driver = 'hot_bunnies'
    else
      driver = 'bunny'
    end
    return driver
  end

  def connect(driver, options={})
    case driver
    when 'hot_bunnies'
      options.delete_if do |k,v|
        %w{ssl verify_ssl logging}.include?(k)
      end
      connection = HotBunnies.connect(options)
    else
      connection = Bunny.new(options)
    end
    return connection
  end

  def start!(driver, connection, prefetch_count)
    case driver
    when 'hot_bunnies'
      # hot_bunnies operates on channel object
      channel = connection.create_channel
      channel.prefetch = prefetch_count
      return channel
    else
      # bunny operations on connection object
      connection.start
      connection.qos({:prefetch_count => prefetch_count})
      return connection
    end
  end

  def do_bind(driver, queue, exchange, key)
    case driver
    when 'hot_bunnies'
      queue.bind(exchange, :routing_key => key)
    else
      queue.bind(exchange, :key => key)
    end
  end

  def do_unbind(driver, queue, exchange, key)
    case driver
    when 'hot_bunnies'
      queue.unbind(exchange, :routing_key => key)
    else
      queue.unbind(exchange, :key => key)
    end
  end
end
