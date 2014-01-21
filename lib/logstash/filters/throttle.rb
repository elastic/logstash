require "logstash/filters/base"
require "logstash/namespace"

# The throttle filter is for throttling the number of events received. The filter
# is configured with a lower bound, the before_count, and upper bound, the after_count,
# and a period of time. All events passing through the filter will be counted based on 
# a key. As long as the count is less than the before_count or greater than the 
# after_count, the event will be "throttled" which means the filter will be considered 
# successful and any tags or fields will be added.
#
# For example, if you wanted to throttle events so you only receive an event after 2 
# occurrences and you get no more than 3 in 10 minutes, you would use the 
# configuration:
#     period => 600
#     before_count => 3
#     after_count => 5
#
# Which would result in:
#     event 1 - throttled (successful filter, period start)
#     event 2 - throttled (successful filter)
#     event 3 - not throttled
#     event 4 - not throttled
#     event 5 - not throttled
#     event 6 - throttled (successful filter)
#     event 7 - throttled (successful filter)
#     event x - throttled (successful filter)
#     period end
#     event 1 - throttled (successful filter, period start)
#     event 2 - throttled (successful filter)
#     event 3 - not throttled
#     event 4 - not throttled
#     event 5 - not throttled
#     event 6 - throttled (successful filter)
#     ...
# 
# Another example is if you wanted to throttle events so you only receive 1 event per 
# hour, you would use the configuration:
#     period => 3600
#     before_count => -1
#     after_count => 1
#
# Which would result in:
#     event 1 - not throttled (period start)
#     event 2 - throttled (successful filter)
#     event 3 - throttled (successful filter)
#     event 4 - throttled (successful filter)
#     event x - throttled (successful filter)
#     period end
#     event 1 - not throttled (period start)
#     event 2 - throttled (successful filter)
#     event 3 - throttled (successful filter)
#     event 4 - throttled (successful filter)
#     ...
# 
# A common use case would be to use the throttle filter to throttle events before 3 and 
# after 5 while using multiple fields for the key and then use the drop filter to remove 
# throttled events. This configuration might appear as:
# 
#     filter {
#       throttle {
#         before_count => 3
#         after_count => 5
#         period => 3600
#         key => "%{host}%{message}"
#         add_tag => "throttled"
#       }
#       if "throttled" in [tags] {
#         drop { }
#       }
#     }
#
# Another case would be to store all events, but only email non-throttled 
# events so the op's inbox isn't flooded with emails in the event of a system error. 
# This configuration might appear as:
#
#     filter {
#       throttle {
#         before_count => 3
#         after_count => 5
#         period => 3600
#         key => "%{message}"
#         add_tag => "throttled"
#       }
#     }
#     output {
#       if "throttled" not in [tags] {
#         email {
#    	    from => "logstash@mycompany.com"
#    	    subject => "Production System Alert"
#    	    to => "ops@mycompany.com"
#    	    via => "sendmail"
#    	    body => "Alert on %{host} from path %{path}:\n\n%{message}"
#    	    options => { "location" => "/usr/sbin/sendmail" }
#         }
#       }
#       elasticsearch_http {
#         host => "localhost"
#         port => "19200"
#       }
#     }
#
# The event counts are cleared after the configured period elapses since the 
# first instance of the event. That is, all the counts don't reset at the same 
# time but rather the throttle period is per unique key value.
#
# Mike Pilone (@mikepilone)
# 
class LogStash::Filters::Throttle < LogStash::Filters::Base

  # The name to use in configuration files.
  config_name "throttle"

  # New plugins should start life at milestone 1.
  milestone 1

  # The key used to identify events. Events with the same key will be throttled
  # as a group.  Field substitutions are allowed, so you can combine multiple
  # fields.
  config :key, :validate => :string, :required => true
  
  # Events less than this count will be throttled. Setting this value to -1, the 
  # default, will cause no messages to be throttled based on the lower bound.
  config :before_count, :validate => :number, :default => -1, :required => false
  
  # Events greater than this count will be throttled. Setting this value to -1, the 
  # default, will cause no messages to be throttled based on the upper bound.
  config :after_count, :validate => :number, :default => -1, :required => false
  
  # The period in seconds after the first occurrence of an event until the count is 
  # reset for the event. This period is tracked per unique key value.  Field
  # substitutions are allowed in this value.  They will be evaluated when the _first_
  # event for a given key is seen.  This allows you to specify that certain kinds
  # of events throttle for a specific period.
  config :period, :validate => :string, :default => "3600", :required => false
  
  # The maximum number of counters to store before the oldest counter is purged. Setting 
  # this value to -1 will prevent an upper bound no constraint on the number of counters  
  # and they will only be purged after expiration. This configuration value should only 
  # be used as a memory control mechanism and can cause early counter expiration if the 
  # value is reached. It is recommended to leave the default value and ensure that your 
  # key is selected such that it limits the number of counters required (i.e. don't 
  # use UUID as the key!)
  config :max_counters, :validate => :number, :default => 100000, :required => false

  # Performs initialization of the filter.
  public
  def register
    @threadsafe = false
  
    @event_counters = Hash.new
    @next_expiration = nil
  end # def register

  # Filters the event. The filter is successful if the event should be throttled.
  public
  def filter(event)
      	  
    # Return nothing unless there's an actual filter event
    return unless filter?(event)
    	  
    now = Time.now
    key = event.sprintf(@key)
    
    # Purge counters if too large to prevent OOM.
    if @max_counters != -1 && @event_counters.size > @max_counters then
      purgeOldestEventCounter()
    end
    
    # Expire existing counter if needed
    if @next_expiration.nil? || now >= @next_expiration then
    	expireEventCounters(now)
    end
    
    @logger.debug? and @logger.debug(
      	  "filters/#{self.class.name}: next expiration", 
      	  { "next_expiration" => @next_expiration })
    
    # Create new counter for this event if this is the first occurrence
    counter = nil
    if !@event_counters.include?(key) then
      period = event.sprintf(@period).to_i
      period = 3600 if period == 0
      expiration = now + period
      @event_counters[key] = { :count => 0, :expiration => expiration }
      
      @logger.debug? and @logger.debug("filters/#{self.class.name}: new event", 
      	  { :key => key, :expiration => expiration })
    end
    
    # Fetch the counter
    counter = @event_counters[key]
    
    # Count this event
    counter[:count] = counter[:count] + 1;
    
    @logger.debug? and @logger.debug("filters/#{self.class.name}: current count", 
      	  { :key => key, :count => counter[:count] })
    
    # Throttle if count is < before count or > after count
    if ((@before_count != -1 && counter[:count] < @before_count) || 
       (@after_count != -1 && counter[:count] > @after_count)) then
      @logger.debug? and @logger.debug(
      	  "filters/#{self.class.name}: throttling event", { :key => key })
      	
      filter_matched(event)
    end
        
  end # def filter
  
  # Expires any counts where the period has elapsed. Sets the next expiration time 
  # for when this method should be called again.
  private
  def expireEventCounters(now) 
    
    @next_expiration = nil
    
    @event_counters.delete_if do |key, counter|
      expiration = counter[:expiration]
      expired = expiration <= now
    
      if expired then
      	@logger.debug? and @logger.debug(
      	  "filters/#{self.class.name}: deleting expired counter", 
      	  { :key => key })
      	  
      elsif @next_expiration.nil? || (expiration < @next_expiration)
      	@next_expiration = expiration
      end
      
      expired
    end
  
  end # def expireEventCounters
  
  # Purges the oldest event counter. This operation is for memory control only 
  # and can cause early period expiration and thrashing if invoked.
  private
  def purgeOldestEventCounter()
    
    # Return unless we have something to purge
    return unless @event_counters.size > 0
    
    oldestCounter = nil
    oldestKey = nil
    
    @event_counters.each do |key, counter|
      if oldestCounter.nil? || counter[:expiration] < oldestCounter[:expiration] then
        oldestKey = key;
        oldestCounter = counter;
      end
    end
    
    @logger.warn? and @logger.warn(
      "filters/#{self.class.name}: Purging oldest counter because max_counters " +
      "exceeded. Use a better key to prevent too many unique event counters.", 
      { :key => oldestKey, :expiration => oldestCounter[:expiration] })
      	  
    @event_counters.delete(oldestKey)
    
  end
end # class LogStash::Filters::Throttle