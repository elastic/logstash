# GELF output
# http://www.graylog2.org/about/gelf
#
# This class doesn't currently use 'eventmachine'-style code, so it may
# block things. Whatever, we can fix that later ;)

require "gelf" # rubygem 'gelf'
require "logstash/namespace"
require "logstash/outputs/base"

class LogStash::Outputs::Gelf < LogStash::Outputs::Base
  public
  def register
    # nothing to do
  end # def register

  public
  def receive(event)
    # TODO(sissel): Use Gelf::Message instead
    gelf = GELF::Notifier.new(@url.host, (@url.port or 12201))
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
    gelf.notify(m)
  end # def receive
end # class LogStash::Outputs::Gelf
