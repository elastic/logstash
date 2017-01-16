# Call this file 'crush.rb' (in logstash/filters, as above)
require "logstash/filters/base"
require "logstash/namespace"

# Bob Webber, Nexage, Inc. 2012-05-01
# 2012-02-02 original version
# 2012-05-31 add optional left and right "end" string options

class LogStash::Filters::Crush < LogStash::Filters::Base
  # Setting the config_name here is required. This is how you
  # configure this filter from your logstash config.
  #
  # filter {
  #   crush { ... }
  # }
  config_name "crush"
  plugin_status "experimental"

  # strip off the beginning and ending of the @message string
  #  removing everything beyond the left and right end strings

  config :leftstop, :validate => :string, :default => ""
  config :rightstop, :validate => :string, :default => ""
  
  public
  def register
    # nothing to do
  end # def register

  public
  def filter(event)
    # process message to remove extraneous strings
    @leftend = event.message.index(@leftstop)
    @rightend = event.message.rindex(@rightstop) + @rightstop.length
    event.message = event.message.slice(@leftend..@rightend) if @rightend >= @leftend
  end # def filter
end # class LogStash::Filters::Crush
