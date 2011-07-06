require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Statsd < LogStash::Outputs::Base
  # Regex stolen from statsd code
  RESERVED_CHARACTERS_REGEX = /[\.\:\|\@]/
  config_name "statsd"

  
  # The address of the Statsd server.
  config :host, :validate => :string

  # The port to connect to on your statsd server.
  config :port, :validate => :number, :default => 8125

  # The statsd namespace to use for this metric
  config :namespace, :validate => :string, :default => "logstash"

  # The name of the sender.
  # Dots will be replaced with underscores
  config :sender, :validate => :string, :default => "%{@source_host}"

  # The type of metric to send (count, increment, decrement, timing)
  config :metric_type, :validate => :string, :default => "increment"

  # The name of the metric. Sent as is to statsd.
  # Note that graphite uses dots as delimiters
  config :metric_name, :validate => :string, :default => "%{@source_path}"

  # The sample rate for the metric
  config :sample_rate, :validate => :number, :default => 1

  # The 'value' for count and timing
  config :metric_value, :validate => :number, :default => ""

  # The final metric sent to statsd will look like the following (assuming defaults)
  # logstash.sender.file_name
  #
  # Enable debugging output?
  config :debug, :validate => :boolean, :default => false

  public
  def register
    require "statsd"
    @client = Statsd.new(@host, @port)
  end # def register

  public
  def receive(event)
    @client.namespace = event.sprintf(@namespace)
    @sender = event.sprintf(@sender)
    @metric_name = event.sprintf(@metric_name)
    @sender = @sender.gsub('::','.').gsub(RESERVED_CHARACTERS_REGEX, '_')
    @metric_name = @metric_name.gsub('::','.').gsub(RESERVED_CHARACTERS_REGEX, '_')
    @stat = "#{@sender}.#{@metric_name}"
    @logger.debug(["statsd sending event", { :host => @host, :event => event, :sender => @sender, :stat => @stat, :metric_type => @metric_type }])
    case @metric_type
    when "increment"
      @client.increment(@stat)
    when "decrement"
      @client.decrement(@stat)
    when "count"
      @client.count(@stat, @metric_value)
    when "timing"
      @client.timing(@stat, @metric_value)
    end
  end # def receive
end # class LogStash::Outputs::Statsd
