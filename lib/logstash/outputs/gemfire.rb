require "logstash/outputs/base"
require "logstash/namespace"

# Push events to a GemFire region.
#
# GemFire is an object database.
#
# To use this plugin you need to add gemfire.jar to your CLASSPATH;
# using format=json requires jackson.jar too.
#
# Note: this plugin has only been tested with GemFire 7.0.
#
class LogStash::Outputs::Gemfire < LogStash::Outputs::Base

  config_name "gemfire"
  plugin_status "experimental"

  # Your client cache name
  config :cache_name, :validate => :string, :default => "logstash"

  # The path to a GemFire client cache XML file.
  #
  # Example:
  #
  #      <client-cache>
  #        <pool name="client-pool">
  #            <locator host="localhost" port="31331"/>
  #        </pool>
  #        <region name="Logstash">
  #            <region-attributes refid="CACHING_PROXY" pool-name="client-pool" >
  #            </region-attributes>
  #        </region>
  #      </client-cache>
  #
  config :cache_xml_file, :validate => :string, :default => nil

  # The region name
  config :region_name, :validate => :string, :default => "Logstash"

  # A sprintf format to use when building keys
  config :key_format, :validate => :string, :default => "%{@source}-%{@timestamp}"

  public
  def register
    import com.gemstone.gemfire.cache.client.ClientCacheFactory
    import com.gemstone.gemfire.pdx.JSONFormatter

    @logger.info("Registering output", :plugin => self)
    connect
  end # def register

  public
  def connect
    begin
      @logger.debug("Connecting to GemFire #{@cache_name}")

      @cache = ClientCacheFactory.new.
        set("name", @cache_name).
        set("cache-xml-file", @cache_xml_file).create
      @logger.debug("Created cache #{@cache.inspect}")

    rescue => e
      if terminating?
        return
      else
        @logger.error("Gemfire connection error (during connect), will reconnect",
                      :exception => e, :backtrace => e.backtrace)
        sleep(1)
        retry
      end
    end

    @region = @cache.getRegion(@region_name);
    @logger.debug("Created region #{@region.inspect}")
  end # def connect

  public
  def receive(event)
    return unless output?(event)

    @logger.debug("Sending event", :destination => to_s, :event => event)

    key = event.sprintf @key_format

    message = JSONFormatter.fromJSON(event.to_json)

    @logger.debug("Publishing message", { :destination => to_s, :message => message, :key => key })
    @region.put(key, message)
  end # def receive

  public
  def to_s
    return "gemfire://#{cache_name}"
  end

  public
  def teardown
    @cache.close if @cache
    @cache = nil
    finished
  end # def teardown
end # class LogStash::Outputs::Gemfire
