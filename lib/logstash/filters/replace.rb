require "logstash/filters/base"
require "logstash/namespace"
require "logstash/time"

# The replace filter is for doing string replacement in a field.
#
# An example use case for this filter is to replace | with " "  to make it more friendly to grok, 
# or to modify archived files that might have a slightly different format.
#
class LogStash::Filters::Replace < LogStash::Filters::Base

  config_name "replace"
  plugin_status "experimental"

  # The string to split on. This is usually a line terminator, but can be any
  # string.
  config :search, :validate => :string
  config :replace, :validate => :string

  # The field who will have contents replaced
  config :field, :validate => :string, :default => "@message"

  public
  def register
    # Nothing to do
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    
    if search.empty? || replace.empty?
      return
    end

    #original_value = event[field]
    #new_value = original_value.gsub(search, replace)

    event[field].gsub!(search, replace)

    @logger.debug("replace event", :search => search, :replace => replace, :field => event[field])
 
  end # def filter

end # class LogStash::Filters::Replace
