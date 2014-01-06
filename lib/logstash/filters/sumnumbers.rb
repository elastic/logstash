require 'logstash/namespace'
require 'logstash/filters/base'


# This filter automatically sum all numbers found inside a string
#
# The sum is returned in a new field, "sumTotal".
# The total numbers summed will be in a new field, "sumNums"
#
# The fields produced by this filter are extra useful used in combination
# with kibana number plotting features.
#
# If the field is an array, all of the numbers in it will be summed.
# If the field is a hash, all of the values of the top-level keys will be summed.
# If the field is a string, it will be split, numbers extracted, and summed.
class LogStash::Filters::SumNumbers < LogStash::Filters::Base
  config_name 'sumnumbers'
  milestone 1

  # The source field for the data. By default is message.
  config :source, :validate => :string, :default => 'message'

  public
  def register
  end

  public
  def filter(event)
    msg = event[@source]
    sumnums = 0
    sumtotal = 0

    if not msg
      return
    end

    # If for some reason the field is an array of values, take the first only.
    if msg.is_a?(Array)
      fields = msg.first.split
      # If msg is json, get an array from the values
    elsif msg.is_a?(Hash)
      fields = msg.values
      # Else, we have a string. Split it.
    else
      fields = msg.split
    end

    for elem in fields
      int = str_as_integer(elem)
      if int != nil
        sumtotal += int
        sumnums += 1
        next
      end
      f = str_as_float(elem)
      if f != nil
        sumtotal += f
        sumnums += 1
      end
    end

    event["sumNums"] = sumnums
    event["sumTotal"] = sumtotal
  end

  def str_as_integer(str)
    Integer(str) rescue nil
  end

  def str_as_float(str)
    Float(str) rescue nil
  end
end # class LogStash::Filters::SumNumbers
