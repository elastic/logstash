# Call this file 'smash.rb' (in logstash/filters, as above)
require "logstash/filters/base"
require "logstash/namespace"

# Bob Webber, Nexage, Inc. 2012-02-02
# Updated with smashpat configuration, Bob W., Nexage, 2012-05-01

class LogStash::Filters::Smash < LogStash::Filters::Base
  # Setting the config_name here is required. This is how you
  # configure this filter from your logstash config.
  #
  # filter {
  #   smash { ... }
  # }
  config_name "smash"
  plugin_status "experimental"

  # Replace the message with this value.
  config :smashpat, :validate => :string, :default => ""

  public
  def register
    # nothing to do
  end # def register

  public
  def filter(event)
    # null out @message
    event.message = @smashpat
  end # def filter
end # class LogStash::Filters::Smash

