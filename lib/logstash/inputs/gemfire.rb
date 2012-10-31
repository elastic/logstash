require "logstash/inputs/threadable"
require "logstash/namespace"

# Push events to a GemFire region.
#
# GemFire is an object database.
class LogStash::Inputs::Gemfire < LogStash::Inputs::Threadable

  config_name "gemfire"
  plugin_status "experimental"

  # Your client cache name
  config :name, :validate => :string, :default => "logstash"

  # A path to a GemFire XML file
  config :cache_xml_file, :validate => :string, :default => nil

  # The region name
  config :region_name, :validate => :string, :default => "Logstash"

  # A regexp to use when registering interest for cache events
  config :interest_regexp, :validate => :string, :default => ".*"

  # How the message is serialized in the cache. Can be one of "json" or "plain"; default is plain
  config :serialization, :validate => :string, :default => nil

  public
  def initialize(params)
    super

    @format ||= "plain"

  end # def initialize

  public
  def register
    import com.gemstone.gemfire.cache.AttributesMutator
    import com.gemstone.gemfire.cache.InterestResultPolicy
    import com.gemstone.gemfire.cache.client.ClientCacheFactory
    import com.gemstone.gemfire.cache.client.ClientRegionShortcut
    import com.gemstone.gemfire.pdx.JSONFormatter

    @logger.info("Registering input", :plugin => self)
  end # def register

  def run(queue)
    return if terminating?
    connect

    @logstash_queue = queue

    register_interest(@interest_regexp)
  end # def run

  def teardown
    @cache.close if @cache
    @cache = nil
    finished
  end # def teardown

  protected
  def connect
    begin
      @logger.debug("Connecting to GemFire #{@name}")

      @cache = ClientCacheFactory.new.
        set("name", @name).
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

  protected
  def register_interest(interest)
    @region.getAttributesMutator.addCacheListener(self)
    @region.registerInterestRegex(interest, InterestResultPolicy::NONE, false, true)
  end

  def deserialize_message(message)
    if @serialization == "json"
      message ? JSONFormatter.toJSON(message) : "{}"
    else
      message
    end
  end

  def process_event(event, event_name, source)
    message = deserialize_message(event)
    e = to_event(message, source)
    if e
      @logstash_queue << e
    end
  end

  #
  # CacheListener interface
  #
  protected
  def afterCreate(event)
    regionName = event.getRegion.getName
    key = event.getKey
    newValue = event.getNewValue
    @logger.debug("afterCreate #{regionName} #{key} #{newValue}")

    process_event(event.getNewValue, "afterCreate", "gemfire://#{regionName}/#{key}/afterCreate")
  end

  def afterDestroy(event)
    regionName = event.getRegion.getName
    key = event.getKey
    newValue = event.getNewValue
    @logger.debug("afterDestroy #{regionName} #{key} #{newValue}")

    process_event(nil, "afterDestroy", "gemfire://#{regionName}/#{key}/afterDestroy")
  end

  def afterUpdate(event)
    regionName = event.getRegion.getName
    key = event.getKey
    oldValue = event.getOldValue
    newValue = event.getNewValue
    @logger.debug("afterUpdate #{regionName} #{key} #{oldValue} -> #{newValue}")

    process_event(event.getNewValue, "afterUpdate", "gemfire://#{regionName}/#{key}/afterUpdate")
  end

  def afterRegionLive(event)
    @logger.debug("afterRegionLive #{event}")
  end

  def afterRegionCreate(event)
    @logger.debug("afterRegionCreate #{event}")
  end

  def afterRegionClear(event)
    @logger.debug("afterRegionClear #{event}")
  end

  def afterRegionDestroy(event)
    @logger.debug("afterRegionDestroy #{event}")
  end

  def afterRegionInvalidate(event)
    @logger.debug("afterRegionInvalidate #{event}")
  end
end # class LogStash::Inputs::Amqp
