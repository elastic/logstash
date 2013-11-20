# encoding: utf-8
require 'logstash/namespace'
require 'logstash/filters/base'


# This filter automatically extracts all numbers found inside a string
#
# This is useful when you have lines that don't match a grok pattern
# or use json but you still need to extract numbers.
#
# Each numbers is returned in a @fields.intX or @fields.floatX field
# where X indicates the position in the string.
#
# The fields produced by this filter are extra useful used in combination
# with kibana number plotting features.
class LogStash::Filters::ExtractNumbers < LogStash::Filters::Base
  config_name 'extractnumbers'
  milestone 1

  # The source field for the data. By default is message.
  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    integers = nil
    floats = nil

    msg = event[@source]

    if not msg
      return
    end

    # If for some reason the field is an array of values, take the first only.
    msg = msg.first if msg.is_a?(Array)


    fields = msg.split
    for elem in fields
      int = str_as_integer(elem)
      if int != nil
        if not integers
          integers = Array.new
        end
        integers.push(int)
        next
      end
      f = str_as_float(elem)
      if f != nil
        if not floats
          floats = Array.new
        end
        floats.push(f)
      end
    end

    if integers
      index = 0
      for i in integers
        index += 1
        event["int" + index.to_s] = i
      end
    end
    if floats
      index = 0
      for f in floats
        index += 1
        event["float" + index.to_s] = f
      end
    end
  end

  def str_as_integer(str)
    Integer(str) rescue nil
  end

  def str_as_float(str)
    Float(str) rescue nil
  end
end # class LogStash::Filters::ExtractNumbers
