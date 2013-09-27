require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Unique < LogStash::Filters::Base

  config_name "unique"
  milestone 1

  # The fields on which to run the unique filter.
  config :fields, :validate => :array, :required => true

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @fields.each do |field|
      continue unless event[field].class == Array

      event[field] = event[field].uniq
    end
  end # def filter

end # class Logstash::Filters::Unique
