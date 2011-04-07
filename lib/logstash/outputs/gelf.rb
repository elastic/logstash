require "gelf" # rubygem 'gelf'
require "logstash/namespace"
require "logstash/outputs/base"

# GELF output. This is most useful if you want to use logstash
# to output events to graylog2.
#
# http://www.graylog2.org/about/gelf
class LogStash::Outputs::Gelf < LogStash::Outputs::Base

  config_name "gelf"
  
  # graylog2 server address
  config :host, :validate => :string, :required => true

  # graylog2 server port
  config :port, :validate => :number, :default => 12201

  # The GELF chunksize
  config :chunksize, :validate => :number, :default => 1420

  # The GELF message level
  config :level, :validate => :number, :default => 1

  # The GELF facility.
  config :facility, :validate => :string, :default => "logstash-gelf"

  public
  def register
    option_hash = Hash.new
    option_hash['level'] = @level
    option_hash['facility'] = @facility

    @gelf = GELF::Notifier.new(@host, @port, @chunksize, option_hash)
  end # def register

  public
  def receive(event)
    m = Hash.new
    m["short_message"] = (event.fields["message"] or event.message)
    m["full_message"] = (event.message)
    m["host"] = event["@source_host"]
    m["file"] = event["@source_path"]
    m["level"] = 1

    event.fields.each do |name, value|
      next if value == nil or value.empty?
      m["#{name}"] = value
    end
    m["timestamp"] = event.timestamp
    @gelf.notify!(m)
  end # def receive
end # class LogStash::Outputs::Gelf
