require "date"
require "logstash/inputs/rabbitmq"
require "zlib"

# Read Zenoss events from the zenoss.zenevents fanout exchange.
#
class LogStash::Inputs::Zenoss < LogStash::Inputs::RabbitMQ

  config_name "zenoss"
  milestone 1

  # Your rabbitmq server address
  config :host, :validate => :string, :default => "localhost"

  # Your rabbitmq username
  config :user, :validate => :string, :default => "zenoss"

  # Your rabbitmq password
  config :password, :validate => :password, :default => "zenoss"

  # The name of the exchange to bind the queue. This is analogous to the 'rabbitmq
  # output' [config 'name'](../outputs/rabbitmq)
  config :exchange, :validate => :string, :default => "zenoss.zenevents"

  # The routing key to use. This is only valid for direct or fanout exchanges
  #
  # * Routing keys are ignored on topic exchanges.
  # * Wildcards are not valid on direct exchanges.
  config :key, :validate => :string, :default => "zenoss.zenevent.#"

  # The vhost to use. If you don't know what this is, leave the default.
  config :vhost, :validate => :string, :default => "/zenoss"

  def register
    super
    require "logstash/util/zenoss"
    require "bunny"
  end # def register

  def run(queue)
    begin
      zep = Org::Zenoss::Protobufs::Zep

      @logger.debug("Connecting with RabbitMQ settings #{@rabbitmq_settings.inspect}")
      @bunny = Bunny.new(@rabbitmq_settings)
      return if terminating?
      @bunny.start
      @bunny.qos({:prefetch_count => @prefetch_count})

      @arguments_hash = Hash[*@arguments]

      @logger.debug("Setting up queue #{@name.inspect}")
      @queue = @bunny.queue(@name, {
        :durable => @durable,
        :auto_delete => @auto_delete,
        :exclusive => @exclusive,
        :arguments => @arguments_hash
      })

      @queue.bind(@exchange, :key => @key)

      @queue.subscribe({:ack => @ack}) do |data|

        # Zenoss can optionally compress message payloads.
        if data[:header].content_encoding == "deflate"
          data[:payload] = Zlib::Inflate.inflate(data[:payload])
        end

        # Decode the payload into an EventSummary.
        summary = zep::EventSummary.decode(data[:payload])

        # This should never happen, but skip it if it does.
        next unless summary.occurrence.length > 0

        occurrence = summary.occurrence[0]
        #timestamp = DateTime.strptime(occurrence.created_time.to_s, "%Q").to_s
        timestamp = Time.at(occurrence.created_time / 1000.0)

        # LogStash event properties.
        event = LogStash::Event.new(
          "@timestamp" => timestamp,
          "type" => @type,
          "host" => occurrence.actor.element_title,
          "message" => occurrence.message,
        )
        decorate(event)

        # Direct mappings from summary.
        %w{uuid}.each do |property|
          property_value = occurrence.send property
          if !property_value.nil?
            event[property] = property_value
          end
        end

        # Direct mappings from occurrence.
        %w{
          fingerprint event_class event_class_key event_key event_group agent
          syslog_facility nt_event_code monitor
        }.each do |property|
          property_value = occurrence.send property
          if !property_value.nil?
            event[property] = property_value
          end
        end

        # Enum Mappings.
        event["severity"] = zep::EventSeverity.constants[occurrence.severity]

        if !occurrence.status.nil?
          event["status"] = zep::EventStatus.constants[occurrence.status]
        end

        if !occurrence.syslog_priority.nil?
          event["syslog_priority"] = zep::SyslogPriority.constants[
            occurrence.syslog_priority]
        end

        # Extra Details.
        if !occurrence.details.nil?
          occurrence.details.each do |detail|
            if detail.value.length == 1
              event[detail.name] = detail.value[0]
            else
              event[detail.name] = detail.value
            end
          end
        end

        queue << event
      end # @queue.subscribe

    rescue *[Bunny::ConnectionError, Bunny::ServerDownError] => e
      @logger.error("RabbitMQ connection error, will reconnect: #{e}")
      # Sleep for a bit before retrying.
      # TODO(sissel): Write 'backoff' method?
      sleep(1)
      retry
    end # begin/rescue
  end # def run

end # class LogStash::Inputs::Zenoss
