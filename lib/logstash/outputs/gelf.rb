require "logstash/namespace"
require "logstash/outputs/base"

# GELF output. This is most useful if you want to use logstash
# to output events to graylog2.
#
# More information at <http://www.graylog2.org/about/gelf>
class LogStash::Outputs::Gelf < LogStash::Outputs::Base

  config_name "gelf"
  plugin_status "beta"

  # graylog2 server address
  config :host, :validate => :string, :required => true

  # graylog2 server port
  config :port, :validate => :number, :default => 12201

  # The GELF chunksize. You usually don't need to change this.
  config :chunksize, :validate => :number, :default => 1420

  # Allow overriding of the gelf 'sender' field. This is useful if you
  # want to use something other than the event's source host as the
  # "sender" of an event. A common case for this is using the application name
  # instead of the hostname.
  config :sender, :validate => :string, :default => "%{@source_host}"

  # The GELF message level. Dynamic values like %{level} are permitted here;
  # useful if you want to parse the 'log level' from an event and use that
  # as the gelf level/severity.
  #
  # Values here can be integers [0..7] inclusive or any of 
  # "debug", "info", "warn", "error", "fatal", "unknown" (case insensitive).
  # Single-character versions of these are also valid, "d", "i", "w", "e", "f",
  # "u"
  config :level, :validate => :array, :default => [ "%{severity}", "%{level}", "INFO" ]

  # The GELF facility. Dynamic values like %{foo} are permitted here; this
  # is useful if you need to use a value from the event as the facility name.
  config :facility, :validate => :string, :default => [ "%{facility}", "logstash-gelf" ]

  # Ship metadata within event object?
  config :ship_metadata, :validate => :boolean, :default => true

  # The GELF custom field mappings. GELF supports arbitrary attributes as custom
  # fields. This exposes that. Exclude the `_` portion of the field name
  # e.g. `custom_fields => ['foo_field', 'some_value']
  # sets `_foo_field` = `some_value`
  config :custom_fields, :validate => :hash, :default => {}

  public
  def register
    require "gelf" # rubygem 'gelf'
    option_hash = Hash.new
    #option_hash['level'] = @level
    #option_hash['facility'] = @facility

    #@gelf = GELF::Notifier.new(@host, @port, @chunksize, option_hash)
    @gelf = GELF::Notifier.new(@host, @port, @chunksize)

    # This sets the 'log level' of gelf; since we're forwarding messages, we'll
    # want to forward *all* messages, so set level to 0 so all messages get
    # shipped
    @gelf.level = 0

    @level_map = {
      "debug" => 7, "d" => 7,
      "info" => 6, "i" => 6,
      "warn" => 5, "w" => 5,
      "error" => 4, "e" => 4,
      "fatal" => 3, "f" => 3,
      "unknown" => 1, "u" => 1,
    }
  end # def register

  public
  def receive(event)
    return unless output?(event)

    # We have to make our own hash here because GELF expects a hash
    # with a specific format.
    m = Hash.new
    if event.fields["message"]
      v = event.fields["message"]
      m["short_message"] = (v.is_a?(Array) && v.length == 1) ? v.first : v
    else
      m["short_message"] = event.message
    end

    m["full_message"] = (event.message)
    
    m["host"] = event.sprintf(@sender)
    m["file"] = event["@source_path"]

    # set facility using optional failover array
    if @facility.is_a?(Array)
      @facility.each do |value|
        parsed_value = event.sprintf(value)
        if !parsed_value.empty?
          m["facility"] = parsed_value
          break
        end
      end
    else
      m["facility"] = event.sprintf(@facility)
    end

    # graylog2 chokes on the old facility field hanging around
    event["@fields"].delete("facility")
    
    if @ship_metadata
        event.fields.each do |name, value|
          next if value == nil
          name = "_id" if name == "id"  # "_id" is reserved, so use "__id"
          if !value.nil?
            if value.is_a?(Array)
              # collapse single-element arrays, otherwise leave as array
              m["_#{name}"] = (value.length == 1) ? value.first : value
            else
              # Non array values should be presented as-is
              # https://logstash.jira.com/browse/LOGSTASH-113
              m["_#{name}"] = value
            end
          end
        end
    end

    if @custom_fields
      @custom_fields.each do |field_name, field_value|
        m["_#{field_name}"] = field_value unless field_name == 'id'
      end
    end

    # Probe severity array levels
    level = nil
    if @level.is_a?(Array)
      @level.each do |value|
        parsed_value = event.sprintf(value)
        if !parsed_value.empty?
          level = parsed_value
          break
        end
      end
    else
      level = event.sprintf(@level.to_s)
    end
    m["level"] = (@level_map[level.downcase] || level).to_i

    @logger.debug(["Sending GELF event", m])
    begin
      @gelf.notify!(m, :timestamp => event.unix_timestamp.to_f)
    rescue
      @logger.warn("Trouble sending GELF event", :gelf_event => m,
                   :event => event, :error => $!)
    end
  end # def receive
end # class LogStash::Outputs::Gelf
