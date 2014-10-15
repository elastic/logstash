# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/environment"
require "set"
#
# This filter will collapse multiline messages from a single source into one Logstash event.
#
# The original goal of this filter was to allow joining of multi-line messages
# from files into a single event. For example - joining java exception and
# stacktrace messages into a single event.
#
# NOTE: This filter will not work with multiple worker threads "-w 2" on the logstash command line.
#
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
# The `pattern` should be a regexp which matches what you believe to be an indicator
# that the field is part of an event consisting of multiple lines of log data.
#
# The `what` must be "previous" or "next" and indicates the relation
# to the multi-line event.
#
# The `negate` can be "true" or "false" (defaults to false). If "true", a
# message not matching the pattern will constitute a match of the multiline
# filter and the `what` will be applied. (vice-versa is also true)
#
# For example, Java stack traces are multiline and usually have the message
# starting at the far-left, with each subsequent line indented. Do this:
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
# This says that any line ending with a backslash should be combined with the
# following line.
#
class LogStash::Filters::Multiline < LogStash::Filters::Base

  config_name "multiline"
  milestone 3

  # The regular expression to match.
  config :pattern, :validate => :string, :required => true

  # If the pattern matched, does event belong to the next or previous event?
  config :what, :validate => ["previous", "next"], :required => true

  # Negate the regexp pattern ('if not matched')
  config :negate, :validate => :boolean, :default => false

  # The stream identity is how the multiline filter determines which stream an
  # event belongs to. This is generally used for differentiating, say, events
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
  config :stream_identity , :validate => :string, :default => "%{host}.%{path}.%{type}"

  # Logstash ships by default with a bunch of patterns, so you don't
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

  # The maximum age an event can be (in seconds) before it is automatically
  # flushed.
  config :max_age, :validate => :number, :default => 5

  # Call the filter flush method at regular interval.
  # Optional.
  config :periodic_flush, :validate => :boolean, :default => true


  # Detect if we are running from a jarfile, pick the right path.
  @@patterns_path = Set.new
  @@patterns_path += [LogStash::Environment.pattern_path("*")]

  MULTILINE_TAG = "multiline"

  public
  def initialize(config = {})
    super

    # this filter cannot be parallelized because message order
    # cannot be garanteed across threads, line #2 could be processed
    # before line #1
    @threadsafe = false

    # this filter needs to keep state
    @pending = Hash.new
  end # def initialize

  public
  def register
    require "grok-pure" # rubygem 'jls-grok'

    @grok = Grok.new

    @patterns_dir = @@patterns_path.to_a + @patterns_dir
    @patterns_dir.each do |path|
      if File.directory?(path)
        path = File.join(path, "*")
      end

      Dir.glob(path).each do |file|
        @logger.info("Grok loading patterns from file", :path => file)
        @grok.add_patterns_from_file(file)
      end
    end

    @grok.compile(@pattern)

    case @what
    when "previous"
      class << self; alias_method :multiline_filter!, :previous_filter!; end
    when "next"
      class << self; alias_method :multiline_filter!, :next_filter!; end
    else
      # we should never get here since @what is validated at config
      raise(ArgumentError, "Unknown multiline 'what' value")
    end # case @what

    @logger.debug("Registered multiline plugin", :type => @type, :config => @config)
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    match = event["message"].is_a?(Array) ? @grok.match(event["message"].first) : @grok.match(event["message"])
    match = (match and !@negate) || (!match and @negate) # add negate option

    @logger.debug? && @logger.debug("Multiline", :pattern => @pattern, :message => event["message"], :match => match, :negate => @negate)

    multiline_filter!(event, match)

    unless event.cancelled?
      collapse_event!(event)
      filter_matched(event) if match
    end
  end # def filter

  # flush any pending messages
  # called at regular interval without options and at pipeline shutdown with the :final => true option
  # @param options [Hash]
  # @option options [Boolean] :final => true to signal a final shutdown flush
  # @return [Array<LogStash::Event>] list of flushed events
  public
  def flush(options = {})
    expired = nil

    # note that thread safety concerns are not necessary here because the multiline filter
    # is not thread safe thus cannot be run in multiple folterworker threads and flushing
    # is called by the same thread

    # select all expired events from the @pending hash into a new expired hash
    # if :final flush then select all events
    expired = @pending.inject({}) do |r, (key, event)|
      age = Time.now - Array(event["@timestamp"]).first.time
      r[key] = event if (age >= @max_age) || options[:final]
      r
    end

    # delete expired items from @pending hash
    expired.each{|key, event| @pending.delete(key)}

    # return list of uncancelled and collapsed expired events
    expired.map{|key, event| event.uncancel; collapse_event!(event)}
  end # def flush

  public
  def teardown
    # nothing to do
  end

  private

  def previous_filter!(event, match)
    key = event.sprintf(@stream_identity)

    pending = @pending[key]

    if match
      event.tag(MULTILINE_TAG)
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
      end
    end # if match
  end

  def next_filter!(event, match)
    key = event.sprintf(@stream_identity)

    # protect @pending for race condition between the flush thread and the worker thread
    pending = @pending[key]

    if match
      event.tag(MULTILINE_TAG)
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
        event.overwrite(pending)
        @pending.delete(key)
      end
    end # if match
  end

  def collapse_event!(event)
    event["message"] = event["message"].join("\n") if event["message"].is_a?(Array)
    event.timestamp = event.timestamp.first if event.timestamp.is_a?(Array)
    event
  end
end # class LogStash::Filters::Multiline
