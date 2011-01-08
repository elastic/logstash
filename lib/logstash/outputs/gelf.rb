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
    gelf = Gelf.new(@url.host, (@url.port or 12201))
    gelf.short_message = (event.fields["message"] or event.message)
    gelf.full_message = (event.message)
    gelf.level = 1
    gelf.host = event["@source_host"]
    gelf.file = event["@source_path"]

    event.fields.each do |name, value|
      next if value == nil or value.empty?
      gelf.add_additional name, value
    end
    gelf.add_additional "event_timestamp", event.timestamp
    gelf.send
  end # def receive
end # class LogStash::Outputs::Gelf
