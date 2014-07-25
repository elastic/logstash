require "logstash/outputs/base"
require "logstash/namespace"

# Push events to memcached or any service using memcached protocol ( eg  Kestrel)

class LogStash::Outputs::Memcached < LogStash::Outputs::Base

  config_name "memcached"
  milestone 1

  # host
  config :host, :validate => :array, :required => true

  # key (queue name in case of Kestrel)
  config :key, :validate => :string, :required => true

  #codec
  default :codec, "json"

  public
  def register
    require 'memcached'
    $memcached = Memcached.new(@host)
    @codec.on_event do |event|
      begin 
	$memcached.set(@key, event)
      rescue Exception => e
	@logger.warn("Unhandled exception", :event => event, :exception => e, :stacktrace => e.backtrace)
      end
    end
  end

  public
  def receive(event)
    return unless output?(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end
    @codec.encode event
  end # def recieve

end # class LogStash::Outputs::Memcached
