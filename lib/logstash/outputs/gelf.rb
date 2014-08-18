# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"

# This output generates messages in GELF format. This is most useful if you
# want to use Logstash to output events to Graylog2.
#
# More information at <http://graylog2.org/gelf#specs>
class LogStash::Outputs::Gelf < LogStash::Outputs::Base

  config_name "gelf"
  milestone 2

  # Graylog2 server IP address or hostname.
  config :host, :validate => :string, :required => true

  # Graylog2 server port number.
  config :port, :validate => :number, :default => 12201

  # The GELF chunksize. You usually don't need to change this.
  config :chunksize, :validate => :number, :default => 1420

  # Allow overriding of the GELF `sender` field. This is useful if you
  # want to use something other than the event's source host as the
  # "sender" of an event. A common case for this is using the application name
  # instead of the hostname.
  config :sender, :validate => :string, :default => "%{host}"

  # The GELF message level. Dynamic values like %{level} are permitted here;
  # useful if you want to parse the 'log level' from an event and use that
  # as the GELF level/severity.
  #
  # Values here can be integers [0..7] inclusive or any of
  # "debug", "info", "warn", "error", "fatal" (case insensitive).
  # Single-character versions of these are also valid, "d", "i", "w", "e", "f",
  # "u"
  # The following additional severity\_labels from Logstash's  syslog\_pri filter
  # are accepted: "emergency", "alert", "critical",  "warning", "notice", and
  # "informational".
  config :level, :validate => :array, :default => [ "%{severity}", "INFO" ]

  # The GELF facility. Dynamic values like %{foo} are permitted here; this
  # is useful if you need to use a value from the event as the facility name.
  # Should now be sent as an underscored "additional field" (e.g. `\_facility`)
  config :facility, :validate => :string, :deprecated => true

  # The GELF line number; this is usually the line number in your program where
  # the log event originated. Dynamic values like %{foo} are permitted here, but the
  # value should be a number.
  # Should now be sent as an underscored "additional field" (e.g. `\_line`).
  config :line, :validate => :string, :deprecated => true

  # The GELF file; this is usually the source code file in your program where
  # the log event originated. Dynamic values like %{foo} are permitted here.
  # Should now be sent as an underscored "additional field" (e.g. `\_file`).
  config :file, :validate => :string, :deprecated => true

  # Should Logstash ship metadata within event object? This will cause Logstash
  # to ship any fields in the event (such as those created by grok) in the GELF
  # messages. These will be sent as underscored "additional fields".
  config :ship_metadata, :validate => :boolean, :default => true

  # Ship tags within events. This will cause Logstash to ship the tags of an
  # event as the field `\_tags`.
  config :ship_tags, :validate => :boolean, :default => true

  # Ignore these fields when `ship_metadata` is set. Typically this lists the
  # fields used in dynamic values for GELF fields.
  config :ignore_metadata, :validate => :array, :default => [ "@timestamp", "@version", "severity", "host", "source_host", "source_path", "short_message" ]

  # The GELF custom field mappings. GELF supports arbitrary attributes as custom
  # fields. This exposes that. Exclude the `_` portion of the field name
  # e.g. `custom_fields => ['foo_field', 'some_value']
  # sets `_foo_field` = `some_value`.
  config :custom_fields, :validate => :hash, :default => {}

  # The GELF full message. Dynamic values like %{foo} are permitted here.
  config :full_message, :validate => :string, :default => "%{message}"

  # The GELF short message field name. If the field does not exist or is empty,
  # the event message is taken instead.
  config :short_message, :validate => :string, :default => "short_message"

  public
  def register
    require "gelf" # rubygem 'gelf'
    option_hash = Hash.new

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
  end # def register

  public
  def receive(event)
    return unless output?(event)

    # We have to make our own hash here because GELF expects a hash
    # with a specific format.
    m = Hash.new

    m["short_message"] = event["message"]
    if event[@short_message]
      v = event[@short_message]
      short_message = (v.is_a?(Array) && v.length == 1) ? v.first : v
      short_message = short_message.to_s
      if !short_message.empty?
        m["short_message"] = short_message
      end
    end

    m["full_message"] = event.sprintf(@full_message)

    m["host"] = event.sprintf(@sender)

    # deprecated fields
    m["facility"] = event.sprintf(@facility) if @facility
    m["file"] = event.sprintf(@file) if @file
    m["line"] = event.sprintf(@line) if @line
    m["line"] = m["line"].to_i if m["line"].is_a?(String) and m["line"] === /^[\d]+$/

    if @ship_metadata
      event.to_hash.each do |name, value|
        next if value == nil
        next if name == "message"

        # Trim leading '_' in the event
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
      m["_tags"] = event["tags"].join(', ') if event["tags"]
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
      @gelf.notify!(m, :timestamp => event.timestamp.to_f)
    rescue
      @logger.warn("Trouble sending GELF event", :gelf_event => m,
                   :event => event, :error => $!)
    end
  end # def receive
end # class LogStash::Outputs::Gelf
