# encoding: utf-8
require "logstash/codecs/base"

# The multiline codec is for taking line-oriented text and merging them into a
# single event.
#
# The original goal of this codec was to allow joining of multi-line messages
# from files into a single event. For example - joining java exception and
# stacktrace messages into a single event.
#
# The config looks like this:
#
#     input {
#       stdin {
#         codec => multiline {
#           pattern => "pattern, a regexp"
#           negate => true or false
#           what => "previous" or "next"
#         }
#       }
#     }
# 
# The 'pattern' should match what you believe to be an indicator that the field
# is part of a multi-line event.
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
#     input {
#       stdin {
#         codec => multiline {
#           pattern => "^\s"
#           what => "previous"
#         }
#       }
#     }
#     
# This says that any line starting with whitespace belongs to the previous line.
#
# Another example is to merge lines not starting with a date up to the previous
# line..
#
#     input {
#       file {
#         path => "/var/log/someapp.log"
#         codec => multiline {
#           # Grok pattern names are valid! :)
#           pattern => "^%{TIMESTAMP_ISO8601} "
#           negate => true
#           what => previous
#         }
#       }
#     }
#     
# This is the base class for logstash codecs.
class LogStash::Codecs::Multiline < LogStash::Codecs::Base
  config_name "multiline"
  milestone 3

  # The regular expression to match
  config :pattern, :validate => :string, :required => true

  # If the pattern matched, does event belong to the next or previous event?
  config :what, :validate => ["previous", "next"], :required => true

  # Negate the regexp pattern ('if not matched')
  config :negate, :validate => :boolean, :default => false

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

  # The character encoding used in this input. Examples include "UTF-8"
  # and "cp1252"
  #
  # This setting is useful if your log files are in Latin-1 (aka cp1252)
  # or in another character set other than UTF-8.
  #
  # This only affects "plain" format logs since json is UTF-8 already.
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  # Tag multiline events with a given tag. This tag will only be added
  # to events that actually have multiple lines in them.
  config :multiline_tag, :validate => :string, :default => "multiline"

  public
  def register
    require "grok-pure" # rubygem 'jls-grok'
    # Detect if we are running from a jarfile, pick the right path.
    patterns_path = []
    if __FILE__ =~ /file:\/.*\.jar!.*/
      patterns_path += ["#{File.dirname(__FILE__)}/../../patterns/*"]
    else
      patterns_path += ["#{File.dirname(__FILE__)}/../../../patterns/*"]
    end

    @grok = Grok.new

    @patterns_dir = patterns_path.to_a + @patterns_dir
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

    @buffer = []
    @handler = method("do_#{@what}".to_sym)
  end # def register
  
  public
  def decode(text, &block)
    text.force_encoding(@charset)
    if @charset != "UTF-8"
      # Convert to UTF-8 if not in that character set.
      text = text.encode("UTF-8", :invalid => :replace, :undef => :replace)
    end

    match = @grok.match(text)
    @logger.debug("Multiline", :pattern => @pattern, :text => text,
                  :match => !match.nil?, :negate => @negate)

    # Add negate option
    match = (match and !@negate) || (!match and @negate)
    @handler.call(text, match, &block)
  end # def decode

  def buffer(text)
    @time = Time.now.utc if @buffer.empty?
    @buffer << text
  end

  def flush(&block)
    if @buffer.any?
      event = LogStash::Event.new("@timestamp" => @time, "message" => @buffer.join("\n"))
      # Tag multiline events
      event.tag @multiline_tag if @multiline_tag && @buffer.size > 1

      yield event
      @buffer = []
    end
  end

  def do_next(text, matched, &block)
    buffer(text)
    flush(&block) if !matched
  end

  def do_previous(text, matched, &block)
    flush(&block) if !matched
    buffer(text)
  end

  public
  def encode(data)
    # Nothing to do.
    @on_event.call(data)
  end # def encode

end # class LogStash::Codecs::Plain
