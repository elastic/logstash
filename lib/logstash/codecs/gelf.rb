require "logstash/codecs/base"
require "json"
require "stringio"
require "zlib"

# GELF codec. This is useful if you want to use logstash
# to output events to graylog2 using for example the
# rabbitmq output.
#
# More information at <http://graylog2.org/gelf#specs>
class LogStash::Codecs::Gelf < LogStash::Codecs::Base
  config_name "gelf"

  milestone 1

  # Allow overriding of the gelf 'sender' field. This is useful if you
  # want to use something other than the event's source host as the
  # "sender" of an event. A common case for this is using the application name
  # instead of the hostname.
  config :sender, :validate => :string, :default => "%{host}"

  # The GELF message level. Dynamic values like %{level} are permitted here;
  # useful if you want to parse the 'log level' from an event and use that
  # as the gelf level/severity.
  #
  # Values here can be integers [0..7] inclusive or any of
  # "debug", "info", "warn", "error", "fatal" (case insensitive).
  # Single-character versions of these are also valid, "d", "i", "w", "e", "f",
  # "u"
  # The following additional severity_labels from logstash's  syslog_pri filter
  # are accepted: "emergency", "alert", "critical",  "warning", "notice", and
  # "informational"
  config :level, :validate => :array, :default => [ "%{severity}", "INFO" ]

  # The GELF facility. Dynamic values like %{foo} are permitted here; this
  # is useful if you need to use a value from the event as the facility name.
  config :facility, :validate => :string, :deprecated => true

  # The GELF line number; this is usually the line number in your program where
  # the log event originated. Dynamic values like %{foo} are permitted here, but the
  # value should be a number.
  config :line, :validate => :string, :deprecated => true

  # The GELF file; this is usually the source code file in your program where
  # the log event originated. Dynamic values like %{foo} are permitted here.
  config :file, :validate => :string, :deprecated => true

  # Ship metadata within event object? This will cause logstash to ship
  # any fields in the event (such as those created by grok) in the GELF
  # messages.
  config :ship_metadata, :validate => :boolean, :default => true

  # Ship tags within events. This will cause logstash to ship the tags of an
  # event as the field _tags.
  config :ship_tags, :validate => :boolean, :default => true

  # Ignore these fields when ship_metadata is set. Typically this lists the
  # fields used in dynamic values for GELF fields.
  config :ignore_metadata, :validate => :array, :default => [ "@timestamp", "@version", "severity", "host", "source_host", "source_path", "short_message" ]

  # The GELF custom field mappings. GELF supports arbitrary attributes as custom
  # fields. This exposes that. Exclude the `_` portion of the field name
  # e.g. `custom_fields => ['foo_field', 'some_value']
  # sets `_foo_field` = `some_value`
  config :custom_fields, :validate => :hash, :default => {}

  # The GELF full message. Dynamic values like %{foo} are permitted here.
  config :full_message, :validate => :string, :default => "%{message}"

  # The GELF short message field name. If the field does not exist or is empty,
  # the event message is taken instead.
  config :short_message, :validate => :string, :default => "short_message"

  public
  def register
    # these are syslog words and abbreviations mapped to RFC 5424 integers
    # and logstash's syslog_pri filter
    @level_map = {
      "debug" => 7, "d" => 7,
      "info" => 6, "i" => 6, "informational" => 6,
      "notice" => 5, "n" => 5,
      "warn" => 4, "w" => 4, "warning" => 4,
      "error" => 3, "e" => 3,
      "critical" => 2, "c" => 2,
      "alert" => 1, "a" => 1,
      "emergency" => 0, "e" => 0,
    }

    # The version of GELF that we conform to
    @gelf_version = "1.0"
  end # register

  private
  def gzip(string)
    wio = StringIO.new("w")
    w_gz = Zlib::GzipWriter.new(wio)
    w_gz.write(string)
    w_gz.close
    compressed = wio.string
  end

  public
  def encode(data)
    @logger.debug(["encode(data)", data])
    m = Hash.new

    m["version"] = @gelf_version;

    m["short_message"] = data["message"]
    if data[@short_message]
      v = data[@short_message]
      short_message = (v.is_a?(Array) && v.length == 1) ? v.first : v
      short_message = short_message.to_s
      if !short_message.empty?
        m["short_message"] = short_message
      end
    end

    m["full_message"] = data.sprintf(@full_message)

    m["host"] = data.sprintf(@sender)

    # deprecated fields
    m["facility"] = data.sprintf(@facility) if @facility
    m["file"] = data.sprintf(@file) if @file
    m["line"] = data.sprintf(@line) if @line
    m["line"] = m["line"].to_i if m["line"].is_a?(String) and m["line"] === /^[\d]+$/

    if @ship_metadata
      data.to_hash.each do |name, value|
        next if value == nil
        next if name == "message"

        # Trim leading '_' in the data
        name = name[1..-1] if name.start_with?('_')
        name = "_id" if name == "id"  # "_id" is reserved, so use "__id"
        if !value.nil? and !@ignore_metadata.include?(name)
          if value.is_a?(Array)
            m["_#{name}"] = value.join(', ')
          elsif value.is_a?(Hash)
            value.each do |hash_name, hash_value|
              m["_#{name}_#{hash_name}"] = hash_value
            end
          else
            # Non array values should be presented as-is
            # https://logstash.jira.com/browse/LOGSTASH-113
            m["_#{name}"] = value
          end
        end
      end
    end

    if @ship_tags
      m["_tags"] = data["tags"].join(', ') if data["tags"]
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
        parsed_value = data.sprintf(value)
        next if value.count('%{') > 0 and parsed_value == value

        level = parsed_value
        break
      end
    else
      level = data.sprintf(@level.to_s)
    end
    m["level"] = (@level_map[level.downcase] || level).to_i

    @logger.debug(["Sending this", m])

    the_json = JSON.generate(m)
    @logger.debug(the_json)

    @on_event.call(gzip(the_json))
  end # def encode

end # class LogStash::Codecs::Gelf
