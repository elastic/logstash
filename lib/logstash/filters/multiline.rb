# multiline filter
#
# This filter will collapse multiline messages into a single event.
# 

require "logstash/filters/base"
require "logstash/namespace"
require "set"

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
#         pattern => "^\s"
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
  plugin_status "stable"

  # The regular expression to match
  config :pattern, :validate => :string, :required => true

  # If the pattern matched, does event belong to the next or previous event?
  config :what, :validate => ["previous", "next"], :required => true

  # Negate the regexp pattern ('if not matched')
  config :negate, :validate => :boolean, :default => false
  
  # The stream identity is how the multiline filter determines which stream an
  # event belongs. This is generally used for differentiating, say, events
  # coming from multiple files in the same file input, or multiple connections
  # coming from a tcp input.
  #
  # The default value here is usually what you want, but there are some cases
  # where you want to change it. One such example is if you are using a tcp
  # input with only one client connecting at any time. If that client
  # reconnects (due to error or client restart), then logstash will identify
  # the new connection as a new stream and break any multiline goodness that
  # may have occurred between the old and new connection. To solve this use
  # case, you can use "%{@source_host}.%{@type}" instead.
  config :stream_identity , :validate => :string, :default => "%{@source}.%{@type}"
  
  # logstash ships by default with a bunch of patterns, so you don't
  # necessarily need to define this yourself unless you are adding additional
  # patterns.
  #
  # Pattern files are plain text with format:
  #
  #     NAME PATTERN
  #
  # For example:
  #
  #     NUMBER \d+
  config :patterns_dir, :validate => :array, :default => []

  # Detect if we are running from a jarfile, pick the right path.
  @@patterns_path = Set.new
  if __FILE__ =~ /file:\/.*\.jar!.*/
    @@patterns_path += ["#{File.dirname(__FILE__)}/../../patterns/*"]
  else
    @@patterns_path += ["#{File.dirname(__FILE__)}/../../../patterns/*"]
  end

  public
  def initialize(config = {})
    super

    @threadsafe = false

    # This filter needs to keep state.
    @types = Hash.new { |h,k| h[k] = [] }
    @pending = Hash.new
  end # def initialize

  public
  def register
    require "grok-pure" # rubygem 'jls-grok'

    @grok = Grok.new

    @patterns_dir = @@patterns_path.to_a + @patterns_dir
    @patterns_dir.each do |path|
      # Can't read relative paths from jars, try to normalize away '../'
      while path =~ /file:\/.*\.jar!.*\/\.\.\//
        # replace /foo/bar/../baz => /foo/baz
        path = path.gsub(/[^\/]+\/\.\.\//, "")
      end

      if File.directory?(path)
        path = File.join(path, "*")
      end

      Dir.glob(path).each do |file|
        @logger.info("Grok loading patterns from file", :path => file)
        @grok.add_patterns_from_file(file)
      end
    end

    @grok.compile(@pattern)

    @logger.debug("Registered multiline plugin", :type => @type, :config => @config)
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    if event.message.is_a?(Array)
      match = @grok.match(event.message.first)
    else
      match = @grok.match(event.message)
    end
    key = event.sprintf(@stream_identity)
    pending = @pending[key]

    @logger.debug("Multiline", :pattern => @pattern, :message => event.message,
                  :match => match, :negate => @negate)

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
      # TODO(sissel): Make this part of the 'register' method.
      @logger.warn("Unknown multiline 'what' value.", :what => @what)
    end # case @what

    if match and !event.cancelled?
      filter_matched(event)
    end
  end # def filter

  # Flush any pending messages. This is generally used for unit testing only.
  public
  def flush
    events = []
    @pending.each do |key, value|
      value.uncancel
      events << value
    end
    @pending.clear
    return events
  end # def flush
end # class LogStash::Filters::Multiline
