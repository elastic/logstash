require "logstash/inputs/threadable"
require "logstash/namespace"

# Push events to a GemFire region.
#
# GemFire is an object database.
#
# To use this plugin you need to add gemfire.jar to your CLASSPATH.
# Using format=json requires jackson.jar too; use of continuous
# queries requires antlr.jar.
#
# Note: this plugin has only been tested with GemFire 7.0.
#
class LogStash::Inputs::Gemfire < LogStash::Inputs::Threadable

  config_name "gemfire"
  milestone 1

  default :codec, "plain"

  # Your client cache name
  config :cache_name, :validate => :string, :default => "logstash"

  # The path to a GemFire client cache XML file.
  #
  # Example:
  #
  #      <client-cache>
  #        <pool name="client-pool" subscription-enabled="true" subscription-redundancy="1">
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

  # A regexp to use when registering interest for cache events.
  # Ignored if a :query is specified.
  config :interest_regexp, :validate => :string, :default => ".*"

  # A query to run as a GemFire "continuous query"; if specified it takes
  # precedence over :interest_regexp which will be ignore.
  #
  # Important: use of continuous queries requires subscriptions to be enabled on the client pool.
  config :query, :validate => :string, :default => nil

  # How the message is serialized in the cache. Can be one of "json" or "plain"; default is plain
  config :serialization, :validate => :string, :default => nil

  public
  def register
    import com.gemstone.gemfire.cache.AttributesMutator
    import com.gemstone.gemfire.cache.InterestResultPolicy
    import com.gemstone.gemfire.cache.client.ClientCacheFactory
    import com.gemstone.gemfire.cache.client.ClientRegionShortcut
    import com.gemstone.gemfire.cache.query.CqQuery
    import com.gemstone.gemfire.cache.query.CqAttributes
    import com.gemstone.gemfire.cache.query.CqAttributesFactory
    import com.gemstone.gemfire.cache.query.QueryService
    import com.gemstone.gemfire.cache.query.SelectResults
    import com.gemstone.gemfire.pdx.JSONFormatter

    @logger.info("Registering input", :plugin => self)
  end # def register

  def run(queue)
    return if terminating?
    connect

    @logstash_queue = queue

    if @query
      continuous_query(@query)
    else
      register_interest(@interest_regexp)
    end
  end # def run

  def teardown
    @cache.close if @cache
    @cache = nil
    finished
  end # def teardown

  protected
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

  protected
  def continuous_query(query)
    qs = @cache.getQueryService

    cqAf = CqAttributesFactory.new
    cqAf.addCqListener(self)
    cqa = cqAf.create

    @logger.debug("Running continuous query #{query}")
    cq = qs.newCq("logstashCQ" + self.object_id.to_s, query, cqa)

    cq.executeWithInitialResults
  end

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

  def process_event(event, event_name)
    message = deserialize_message(event)
    @codec.decode(message) do |event|
      decorate(event)
      @logstash_queue << event
    end
  end

  # multiple interfaces
  def close
  end

  #
  # CqListener interface
  #
  def onEvent(event)
    key = event.getKey
    newValue = event.getNewValue
    @logger.debug("onEvent #{event.getQueryOperation} #{key} #{newValue}")

    process_event(event.getNewValue, "onEvent", "gemfire://query/#{key}/#{event.getQueryOperation}")
  end

  def onError(event)
    @logger.debug("onError #{event}")
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
end # class LogStash::Inputs::Gemfire
