# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Execute ruby code.
#
# For example, to cancel 90% of events, you can do this:
#
#     filter {
#       ruby {
#         # Cancel 90% of events
#         code => "event.cancel if rand <= 0.90"
#       } 
#     } 
#
class LogStash::Filters::Ruby < LogStash::Filters::Base
  config_name "ruby"
  milestone 1

  # Any code to execute at logstash startup-time
  config :init, :validate => :string

  # The code to execute for every event.
  # You will have an 'event' variable available that is the event itself.
  config :code, :validate => :string, :required => true

  public
  def register
    # TODO(sissel): Compile the ruby code
    eval(@init, binding, "(ruby filter init)") if @init
    eval("@codeblock = lambda { |event| #{@code} }", binding, "(ruby filter code)")
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @codeblock.call(event)

    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Ruby
