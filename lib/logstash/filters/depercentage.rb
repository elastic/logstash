require "logstash/filters/base"
require "logstash/namespace"

# The depercentage filter converts percentage strings to a float
# e.g. 34.5% => 0.345

class LogStash::Filters::DePercentage < LogStash::Filters::Base
  config_name "depercentage"
  milestone 1

  # The fields which should be converted
  # Example:
  #
  #     filter {
  #       depercentage {
  #         # Converts 'profit' field from 34.5% to 0.345
  #         convert => [ "profit", "bytes" ]
  #       }
  #     }
  config :convert, :validate => :array

  public
  def register
    @percentage_regexp = /^(\d+(?:\.\d+)?)\s*\%$/
    # nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    convert(event) if @convert
    filter_matched(event)
  end # def filter

  def convert(event)
    @convert.each do |field|
      next unless event.include?(field)
      original = event[field]
      if original !~ @percentage_regexp
        @logger.debug("Cannot depercentage this value: ", :value => original )
        next
      end
      value = $1.to_f / 100.0
      event[field] = value
    end # end @convert.each
  end # def convert
end # class LogStash::Filters::DePercentage


