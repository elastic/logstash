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
  config :level, :validate => :array, :default => [ "%{severity}", "INFO" ]

  # The GELF facility. Dynamic values like %{foo} are permitted here; this
  # is useful if you need to use a value from the event as the facility name.
  config :facility, :validate => :string, :default => "logstash-gelf"

  # The GELF line number; this is usually the line number in your program where
  # the log event originated. Dynamic values like %{foo} are permitted here, but the
  # value should be a number.
  config :line, :validate => :string

  # The GELF file; this is usually the source code file in your program where
  # the log event originated. Dynamic values like %{foo} are permitted here.
  config :file, :validate => :string, :default => "%{@source_path}"

  # Ship metadata within event object? This will cause logstash to ship
  # any fields in the event (such as those created by grok) in the GELF
  # messages.
  config :ship_metadata, :validate => :boolean, :default => true

  # The GELF custom field mappings. GELF supports arbitrary attributes as custom
  # fields. This exposes that. Exclude the `_` portion of the field name
  # e.g. `custom_fields => ['foo_field', 'some_value']
  # sets `_foo_field` = `some_value`
  config :custom_fields, :validate => :hash, :default => {}

  # The GELF full message. Dynamic values like %{foo} are permitted here.
  config :full_message, :validate => :string, :default => "%{@message}"

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

    # Since we use gelf-rb which assumes the severity level integer
    # is coming from a ruby logging subsystem, we need to instruct it
    # that the levels we provide should be mapped directly since they're
    # already RFC 5424 compliant
    # this requires gelf-rb commit bb1f4a9 which added the level_mapping def
    level_mapping = Hash.new
    (0..7).step(1) { |l| level_mapping[l]=l }
    @gelf.level_mapping = level_mapping

    # If we leave that set, the gelf gem will extract the file and line number
    # of the source file that logged the message (i.e. logstash/gelf.rb:138).
    # With that set to false, it can use the actual event's filename (i.e.
    # /var/log/syslog), which is much more useful
    @gelf.collect_file_and_line = false

    # these are syslog words and abbreviations mapped to RFC 5424 integers
    @level_map = {
      "debug" => 7, "d" => 7,
      "info" => 6, "i" => 6,
      "notice" => 5, "n" => 5,
      "warn" => 4, "w" => 4, "warning" => 4,
      "error" => 3, "e" => 3,
      "critical" => 2, "c" => 2,
      "alert" => 1, "a" => 1,
      "emergency" => 0, "e" => 0,
     }

     @ignore_fields = [ "facility", "full_message", "short_message", "host", "level", "line", "timestamp", "version", "file" ]
  end # def register

  public
  def receive(event)
    return unless output?(event)

    # We have to make our own hash here because GELF expects a hash
    # with a specific format.
    m = Hash.new
    if event.fields["short_message"]
      v = event.fields["short_message"]
      m["short_message"] = (v.is_a?(Array) && v.length == 1) ? v.first : v
    else
      m["short_message"] = event.message
    end

    m["full_message"] = event.sprintf(@full_message)

    m["host"] = event.sprintf(@sender)
    m["file"] = event.sprintf(@file)
    m["line"] = event.sprintf(@line) if @line
    m["line"] = m["line"].to_i if m["line"].is_a?(String) and m["line"] === /^[\d]+$/

    if @ship_metadata
      event.fields.each do |name, value|
        next if value == nil

        # Trim leading '_' in the event
        name = name[1..-1] if name.start_with?('_')
        name = "_id" if name == "id"  # "_id" is reserved, so use "__id"
        if !value.nil? and !@ignore_fields.include?(name)
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

    # set facility as defined
    m["facility"] = event.sprintf(@facility)

    # Probe severity array levels
    level = nil
    if @level.is_a?(Array)
      @level.each do |value|
        parsed_value = event.sprintf(value)
        next if value.count('%{') > 0 and parsed_value == value

        level = parsed_value
        break
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
