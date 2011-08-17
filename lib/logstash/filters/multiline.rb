# multiline filter
#
# This filter will collapse multiline messages into a single event.
# 

require "logstash/filters/base"
require "logstash/namespace"

# The multiline filter is for combining multiple events from a single source
# into the same event.
#
# The original goal of this filter was to allow joining of multi-line messages
# from files into a single event. For example - joining java exception and
# stacktrace messages into a single event.
#
# TODO(sissel): Document any issues?
# The config looks like this:
#
#     filter {
#       multiline {
#         type => "type"
#         pattern => "pattern, a regexp"
#         negate => boolean
#         what => "previous" or "next"
#       }
#     }
# 
# The 'regexp' should match what you believe to be an indicator that
# the field is part of a multi-line event
#
# The 'what' must be "previous" or "next" and indicates the relation
# to the multi-line event.
#
# The 'negate' can be "true" or "false" (defaults false). If true, a 
# message not matching the pattern will constitute a match of the multiline
# filter and the what will be applied. (vice-versa is also true)
#
# For example, java stack traces are multiline and usually have the message
# starting at the far-left, then each subsequent line indented. Do this:
# 
#     filter {
#       multiline {
#         type => "somefiletype"
#         pattern => "^\\s"
#         what => "previous"
#       }
#     }
#     
# This says that any line starting with whitespace belongs to the previous line.
#
# Another example is C line continuations (backslash). Here's how to do that:
#
#     filter {
#       multiline {
#         type => "somefiletype "
#         pattern => "\\$"
#         what => "next"
#       }
#     }
#     
class LogStash::Filters::Multiline < LogStash::Filters::Base

  config_name "multiline"

  # The regular expression to match
  config :pattern, :validate => :string, :require => true

  # If the pattern matched, does event belong to the next or previous event?
  config :what, :validate => ["previous", "next"], :require => true

  # Negate the regexp pattern ('if not matched')
  config :negate, :validate => :boolean, :default => false

  public
  def initialize(config = {})
    super

    # This filter needs to keep state.
    @types = Hash.new { |h,k| h[k] = [] }
    @pending = Hash.new
  end # def initialize

  public
  def register
    @logger.debug "Setting type #{@type.inspect} to the config #{@config.inspect}"

    begin
      @pattern = Regexp.new(@pattern)
    rescue RegexpError => e
      @logger.fatal(["Invalid pattern for multiline filter on type '#{@type}'",
                    @pattern, e])
    end
  end # def register

  public
  def filter(event)
    return unless event.type == @type

    match = @pattern.match(event.message)
    key = [event.source, event.type]
    pending = @pending[key]

    @logger.debug(["Reg: ", @pattern, event.message, { :match => match, :negate => @negate }])

    # Add negate option
    match = (match and !@negate) || (!match and @negate)

    case @what
    when "previous"
      if match
        event.tags |= ["multiline"]
        # previous previous line is part of this event.
        # append it to the event and cancel it
        if pending
          pending.append(event)
        else
          @pending[key] = event
        end
        event.cancel
      else
        # this line is not part of the previous event
        # if we have a pending event, it's done, send it.
        # put the current event into pending
        if pending
          tmp = event.to_hash
          event.overwrite(pending)
          @pending[key] = LogStash::Event.new(tmp)
        else
          @pending[key] = event
          event.cancel
        end # if/else pending
      end # if/else match
    when "next"
      if match
        event.tags |= ["multiline"]
        # this line is part of a multiline event, the next
        # line will be part, too, put it into pending.
        if pending
          pending.append(event)
        else
          @pending[key] = event
        end
        event.cancel
      else
        # if we have something in pending, join it with this message
        # and send it. otherwise, this is a new message and not part of
        # multiline, send it.
        if pending
          pending.append(event)
          event.overwrite(pending.to_hash)
          @pending.delete(key)
        end
      end # if/else match
    else
      @logger.warn(["Unknown multiline 'what' value.", { :what => @what }])
    end # case @what

    if !event.cancelled?
      filter_matched(event)
    end
    filter_matched(event) if !event.cancelled?
  end # def filter

  # flush any pending messages
  public
  def flush(source, type)
    key = [source, type]
    if @pending[key]
      event = @pending[key]
      @pending.delete(key)
    end
    return event
  end # def flush
end # class LogStash::Filters::Date
