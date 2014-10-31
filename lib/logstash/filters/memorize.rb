# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "set"
#
# This filter will look for fields from an event and record the last value
# of them.  If any are not present, their last value will be added to the
# event.  This is useful if you want to use data from a previous event
# on future events (for example a time field or an id field).  This differs
# frome the multiline filter where you are combining multiple lines to
# create a single event.
#
# The config looks like this:
#
#     filter {
#       memorize {
#         fields => [ "time", "id" ]
#         default => { "time" => "00:00:00.000" }
#       }
#     }
#
# The `fields` is an array of the field NAMES that you want to memorize
# The `default` is a map of field names to field values that you want
# to use if the field isn't present and has no memorized value (optional)

class LogStash::Filters::Memorize < LogStash::Filters::Base

  config_name "memorize"
  milestone 2

  # An array of the field names to to memorize
  config :fields, :validate => :array, :required => true
  # a map for default values to use if its not seen before we need it
  config :default, :validate => :hash, :required => false

  # The stream identity is how the filter determines which stream an
  # event belongs to. See the multiline plugin if you want more details on how
  # this might work
  config :stream_identity , :validate => :string, :default => "%{host}.%{path}.%{type}"

  public
  def initialize(config = {})
    super

    @threadsafe = false

    # This filter needs to keep state.
    @memorized = Hash.new
  end # def initialize

  public
  def register
	# nothing needed
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    any = false
    @fields.each do |field|
      if event[field].nil?
	map = @memorized[@stream_identity]
        val = map.nil? ? nil : map[field]
        if val.nil?
          val = @default.nil? ? nil : @default[field]
        end
	if !val.nil?
          event[field] = val
          any = true
	end
      else
        map = @memorized[@stream_identity]
	if map.nil?
          map = @memorized[@stream_identity] = Hash.new
	end
	val = event[field]
	map[field] = event[field]
      end #if
      if any
        filter_matched(event)
      end
    end #field.each
  end
end
