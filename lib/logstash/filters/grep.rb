require "logstash/filters/base"
require "logstash/namespace"

# Grep filter. Useful for dropping events you don't want to pass, or
# adding tags or fields to events that match.
#
# Events not matched are dropped. If 'negate' is set to true (defaults false),
# then matching events are dropped.
class LogStash::Filters::Grep < LogStash::Filters::Base

  config_name "grep"
  milestone 3

  # Drop events that don't match
  #
  # If this is set to false, no events will be dropped at all. Rather, the
  # requested tags and fields will be added to matching events, and
  # non-matching events will be passed through unchanged.
  config :drop, :validate => :boolean, :default => true

  # Negate the match. Similar to 'grep -v'
  #
  # If this is set to true, then any positive matches will result in the
  # event being cancelled and dropped. Non-matching will be allowed
  # through.
  config :negate, :validate => :boolean, :default => false

  # A hash of matches of field => regexp.  If multiple matches are specified,
  # all must match for the grep to be considered successful.  Normal regular
  # expressions are supported here.
  #
  # For example:
  #
  #     filter {
  #       grep {
  #         match => [ "message", "hello world" ]
  #       }
  #     }
  #
  # The above will drop all events with a message not matching "hello world" as
  # a regular expression.
  config :match, :validate => :hash, :default => {}

  # Use case-insensitive matching. Similar to 'grep -i'
  #
  # If enabled, ignore case distinctions in the patterns.
  config :ignore_case, :validate => :boolean, :default => false

  public
  def register
    @logger.warn("The 'grep' plugin is no longer necessary now that you can do if/elsif/else in logstash configs. This plugin will be removed in the future. If you need to drop events, please use the drop filter. If you need to take action based on a match, use an 'if' block and the mutate filter. See the following URL for details on how to use if/elsif/else in your logstash configs:http://logstash.net/docs/#{LOGSTASH_VERSION}/configuration")

    @patterns = Hash.new { |h,k| h[k] = [] }

      # TODO(sissel): 
    @match.each do |field, pattern|

      pattern = [pattern] if pattern.is_a?(String)
      pattern.each do |p|
        re = Regexp.new(p, @ignore_case ? Regexp::IGNORECASE : 0)
        @patterns[field] << re
        @logger.debug? and @logger.debug("Registered grep", :type => @type, :field => field,
                    :pattern => p, :regexp => re)
      end
    end # @match.merge.each
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running grep filter", :event => event, :config => config)
    matches = 0

    # If negate is set but no patterns are given, drop the event.
    # This is useful in cases where you want to drop all events with
    # a given type or set of tags
    #
    # filter {
    #   grep {
    #     negate => true
    #     type => blah
    #   }
    # }
    if @negate && @patterns.empty?
      event.cancel
      return
    end

    @patterns.each do |field, regexes|
      # For each match object, we have to match everything in order to
      # apply any fields/tags.
      match_count = 0
      match_want = 0
      regexes.each do |re|
        match_want += 1

        # Events without this field, with negate enabled, count as a match.
        # With negate disabled, we can't possibly match, so skip ahead.
        if event[field].nil?
          if @negate
            msg = "Field not present, but negate is true; marking as a match"
            @logger.debug(msg, :field => field, :event => event)
            match_count += 1
          else
            @logger.debug("Skipping match object, field not present",
                          :field => field, :event => event)
          end
          # Either way, don't try to process -- may end up with extra unwanted
          # +1's to match_count
          next
        end

        (event[field].is_a?(Array) ? event[field] : [event[field]]).each do |value|
          value = value.to_s if value.is_a?(Numeric)
          if @negate
            @logger.debug("negate match", :regexp => re, :value => value)
            next if re.match(value)
            @logger.debug("grep not-matched (negate requested)", field => value)
          else
            @logger.debug("want match", :regexp => re, :value => value)
            next unless re.match(value)
            @logger.debug("grep matched", field => value)
          end
          match_count += 1
          break
        end # each value in event[field]
      end # regexes.each

      if match_count == match_want
        matches += 1
        @logger.debug("matched all fields", :count => match_count)
      else
        @logger.debug("match failed", :count => match_count, :wanted => match_want)
      end # match["match"].each
    end # @patterns.each

    if matches == @patterns.length
      filter_matched(event)
    else
      if @drop == true
        @logger.debug("grep: dropping event, no matches")
        event.cancel
      else
        @logger.debug("grep: no matches, but drop set to false")
      end
      return
    end

    @logger.debug("Event after grep filter", :event => event)
  end # def filter
end # class LogStash::Filters::Grep
