# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "logstash/environment"
require "set"

# Parse arbitrary text and structure it.
#
# Grok is currently the best way in logstash to parse crappy unstructured log
# data into something structured and queryable.
#
# This tool is perfect for syslog logs, apache and other webserver logs, mysql
# logs, and in general, any log format that is generally written for humans
# and not computer consumption.
#
# Logstash ships with about 120 patterns by default. You can find them here:
# <https://github.com/logstash/logstash/tree/v%VERSION%/patterns>. You can add
# your own trivially. (See the patterns_dir setting)
#
# If you need help building patterns to match your logs, you will find the
# <http://grokdebug.herokuapp.com> too quite useful!
#
# #### Grok Basics
#
# Grok works by combining text patterns into something that matches your
# logs.
#
# The syntax for a grok pattern is `%{SYNTAX:SEMANTIC}`
#
# The `SYNTAX` is the name of the pattern that will match your text. For
# example, "3.44" will be matched by the NUMBER pattern and "55.3.244.1" will
# be matched by the IP pattern. The syntax is how you match.
#
# The `SEMANTIC` is the identifier you give to the piece of text being matched.
# For example, "3.44" could be the duration of an event, so you could call it
# simply 'duration'. Further, a string "55.3.244.1" might identify the 'client'
# making a request.
#
# For the above example, your grok filter would look something like this:
#
# %{NUMBER:duration} %{IP:client}
#
# Optionally you can add a data type conversion to your grok pattern. By default
# all semantics are saved as strings. If you wish to convert a semantic's data type,
# for example change a string to an integer then suffix it with the target data type.
# For example `%{NUMBER:num:int}` which converts the 'num' semantic from a string to an
# integer. Currently the only supported conversions are `int` and `float`.
#
# #### Example
#
# With that idea of a syntax and semantic, we can pull out useful fields from a
# sample log like this fictional http request log:
#
#     55.3.244.1 GET /index.html 15824 0.043
#
# The pattern for this could be:
#
#     %{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}
#
# A more realistic example, let's read these logs from a file:
#
#     input {
#       file {
#         path => "/var/log/http.log"
#       }
#     }
#     filter {
#       grok {
#         match => [ "message", "%{IP:client} %{WORD:method} %{URIPATHPARAM:request} %{NUMBER:bytes} %{NUMBER:duration}" ]
#       }
#     }
#
# After the grok filter, the event will have a few extra fields in it:
#
# * client: 55.3.244.1
# * method: GET
# * request: /index.html
# * bytes: 15824
# * duration: 0.043
#
# #### Regular Expressions
#
# Grok sits on top of regular expressions, so any regular expressions are valid
# in grok as well. The regular expression library is Oniguruma, and you can see
# the full supported regexp syntax [on the Onigiruma
# site](http://www.geocities.jp/kosako3/oniguruma/doc/RE.txt).
#
# #### Custom Patterns
#
# Sometimes logstash doesn't have a pattern you need. For this, you have
# a few options.
#
# First, you can use the Oniguruma syntax for 'named capture' which will
# let you match a piece of text and save it as a field:
#
#     (?<field_name>the pattern here)
#
# For example, postfix logs have a 'queue id' that is an 10 or 11-character
# hexadecimal value. I can capture that easily like this:
#
#     (?<queue_id>[0-9A-F]{10,11})
#
# Alternately, you can create a custom patterns file.
#
# * Create a directory called `patterns` with a file in it called `extra`
#   (the file name doesn't matter, but name it meaningfully for yourself)
# * In that file, write the pattern you need as the pattern name, a space, then
#   the regexp for that pattern.
#
# For example, doing the postfix queue id example as above:
#
#     # contents of ./patterns/postfix:
#     POSTFIX_QUEUEID [0-9A-F]{10,11}
#
# Then use the `patterns_dir` setting in this plugin to tell logstash where
# your custom patterns directory is. Here's a full example with a sample log:
#
#     Jan  1 06:25:43 mailserver14 postfix/cleanup[21403]: BEF25A72965: message-id=<20130101142543.5828399CCAF@mailserver14.example.com>
#
#     filter {
#       grok {
#         patterns_dir => "./patterns"
#         match => [ "message", "%{SYSLOGBASE} %{POSTFIX_QUEUEID:queue_id}: %{GREEDYDATA:syslog_message}" ]
#       }
#     }
#
# The above will match and result in the following fields:
#
# * timestamp: Jan  1 06:25:43
# * logsource: mailserver14
# * program: postfix/cleanup
# * pid: 21403
# * queue_id: BEF25A72965
# * syslog_message: message-id=<20130101142543.5828399CCAF@mailserver14.example.com>
#
# The `timestamp`, `logsource`, `program`, and `pid` fields come from the
# SYSLOGBASE pattern which itself is defined by other patterns.
class LogStash::Filters::Grok < LogStash::Filters::Base
  config_name "grok"
  milestone 3

  # Specify a pattern to parse with. This will match the 'message' field.
  #
  # If you want to match other fields than message, use the 'match' setting.
  # Multiple patterns is fine.
  config :pattern, :validate => :array, :deprecated => "You should use this instead: match => { \"message\" => \"your pattern here\" }"

  # A hash of matches of field => value
  #
  # For example:
  #
  #     filter {
  #       grok {
  #         match => [ "message", "Duration: %{NUMBER:duration}" ]
  #       }
  #     }
  #
  config :match, :validate => :hash, :default => {}

  #
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

  # Drop if matched. Note, this feature may not stay. It is preferable to combine
  # grok + grep filters to do parsing + dropping.
  config :drop_if_match, :validate => :boolean, :default => false

  # Break on first match. The first successful match by grok will result in the
  # filter being finished. If you want grok to try all patterns (maybe you are
  # parsing different things), then set this to false.
  config :break_on_match, :validate => :boolean, :default => true

  # If true, only store named captures from grok.
  config :named_captures_only, :validate => :boolean, :default => true

  # If true, keep empty captures as event fields.
  config :keep_empty_captures, :validate => :boolean, :default => false

  # If true, make single-value fields simply that value, not an array
  # containing that one value.
  config :singles, :validate => :boolean, :default => true, :deprecated => "This behavior is the default now, you don't need to set it."

  # Append values to the 'tags' field when there has been no
  # successful match
  config :tag_on_failure, :validate => :array, :default => ["_grokparsefailure"]

  # The fields to overwrite.
  #
  # This allows you to overwrite a value in a field that already exists.
  #
  # For example, if you have a syslog line in the 'message' field, you can
  # overwrite the 'message' field with part of the match like so:
  #
  #     filter {
  #       grok {
  #         match => [
  #           "message",
  #           "%{SYSLOGBASE} %{DATA:message}"
  #         ]
  #         overwrite => [ "message" ]
  #       }
  #     }
  #
  #  In this case, a line like "May 29 16:37:11 sadness logger: hello world"
  #  will be parsed and 'hello world' will overwrite the original message.
  config :overwrite, :validate => :array, :default => []

  # Detect if we are running from a jarfile, pick the right path.
  @@patterns_path ||= Set.new
  @@patterns_path += [LogStash::Environment.pattern_path("*")]

  public
  def initialize(params)
    super(params)
    @match["message"] ||= []
    @match["message"] += @pattern if @pattern # the config 'pattern' value (array)
    # a cache of capture name handler methods.
    @handlers = {}
  end

  public
  def register
    require "grok-pure" # rubygem 'jls-grok'

    @patternfiles = []

    # Have @@patterns_path show first. Last-in pattern definitions win; this
    # will let folks redefine built-in patterns at runtime.
    @patterns_dir = @@patterns_path.to_a + @patterns_dir
    @logger.info? and @logger.info("Grok patterns path", :patterns_dir => @patterns_dir)
    @patterns_dir.each do |path|
      if File.directory?(path)
        path = File.join(path, "*")
      end

      Dir.glob(path).each do |file|
        @logger.info? and @logger.info("Grok loading patterns from file", :path => file)
        @patternfiles << file
      end
    end

    @patterns = Hash.new { |h,k| h[k] = [] }

    @logger.info? and @logger.info("Match data", :match => @match)

    @match.each do |field, patterns|
      patterns = [patterns] if patterns.is_a?(String)

      if !@patterns.include?(field)
        @patterns[field] = Grok::Pile.new
        #@patterns[field].logger = @logger

        add_patterns_from_files(@patternfiles, @patterns[field])
      end
      @logger.info? and @logger.info("Grok compile", :field => field, :patterns => patterns)
      patterns.each do |pattern|
        @logger.debug? and @logger.debug("regexp: #{@type}/#{field}", :pattern => pattern)
        @patterns[field].compile(pattern)
      end
    end # @match.each
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    matched = false
    done = false

    @logger.debug? and @logger.debug("Running grok filter", :event => event);
    @patterns.each do |field, grok|
      if match(grok, field, event)
        matched = true
        break if @break_on_match
      end
      #break if done
    end # @patterns.each

    if matched
      filter_matched(event)
    else
      # Tag this event if we can't parse it. We can use this later to
      # reparse+reindex logs if we improve the patterns given.
      @tag_on_failure.each do |tag|
        event["tags"] ||= []
        event["tags"] << tag unless event["tags"].include?(tag)
      end
    end

    @logger.debug? and @logger.debug("Event now: ", :event => event)
  end # def filter

  private
  def match(grok, field, event)
    input = event[field]
    if input.is_a?(Array)
      success = true
      input.each do |input|
        grok, match = grok.match(input)
        if match
          match.each_capture do |capture, value|
            handle(capture, value, event)
          end
        else
          success = false
        end
      end
      return success
    #elsif input.is_a?(String)
    else
      # Convert anything else to string (number, hash, etc)
      grok, match = grok.match(input.to_s)
      return false if !match

      match.each_capture do |capture, value|
        handle(capture, value, event)
      end
      return true
    end
  rescue StandardError => e
    @logger.warn("Grok regexp threw exception", :exception => e.message)
  end

  private
  def handle(capture, value, event)
    handler = @handlers[capture] ||= compile_capture_handler(capture)
    return handler.call(value, event)
  end

  private
  def compile_capture_handler(capture)
    # SYNTAX:SEMANTIC:TYPE
    syntax, semantic, coerce = capture.split(":")

    # each_capture do |fullname, value|
    #   capture_handlers[fullname].call(value, event)
    # end

    code = []
    code << "# for capture #{capture}"
    code << "lambda do |value, event|"
    #code << "  p :value => value, :event => event"
    if semantic.nil?
      if @named_captures_only
        # Abort early if we are only keeping named (semantic) captures
        # and this capture has no semantic name.
        code << "  return"
      else
        field = syntax
      end
    else
      field = semantic
    end
    code << "  return if value.nil? || value.empty?" unless @keep_empty_captures
    if coerce
      case coerce
        when "int"; code << "  value = value.to_i"
        when "float"; code << "  value = value.to_f"
      end
    end

    code << "  # field: #{field}"
    if @overwrite.include?(field)
      code << "  event[field] = value"
    else
      code << "  v = event[field]"
      code << "  if v.nil?"
      code << "    event[field] = value"
      code << "  elsif v.is_a?(Array)"
      code << "    event[field] << value"
      code << "  elsif v.is_a?(String)"
      # Promote to array since we aren't overwriting.
      code << "    event[field] = [v, value]"
      code << "  end"
    end
    code << "  return"
    code << "end"

    #puts code
    return eval(code.join("\n"), binding, "<grok capture #{capture}>")
  end # def compile_capture_handler

  private
  def add_patterns_from_files(paths, pile)
    paths.each { |path| add_patterns_from_file(path, pile) }
  end # def add_patterns_from_files

  private
  def add_patterns_from_file(path, pile)
    pile.add_patterns_from_file(path)
  end # def add_patterns_from_file
end # class LogStash::Filters::Grok
