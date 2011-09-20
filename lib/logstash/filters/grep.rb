require "logstash/filters/base"
require "logstash/namespace"

# Grep filter. Useful for dropping events you don't want to pass, or
# adding tags or fields to events that match.
#
# Events not matched are dropped. If 'negate' is set to true (defaults false),
# then matching events are dropped.
class LogStash::Filters::Grep < LogStash::Filters::Base

  config_name "grep"

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

  # A hash of matches of field => regexp
  # Normal regular expressions are supported here.
  config :match, :validate => :hash, :default => {}

  # Config for grep is:
  #   fieldname: pattern
  #   Allow arbitrary keys for this config.
  config /[A-Za-z0-9_-]+/, :validate => :string

  public
  def register
    @patterns = Hash.new { |h,k| h[k] = [] }
      # TODO(sissel): 
    @match.merge(@config).each do |field, pattern|
      # Skip known config names
      next if ["add_tag", "add_field", "type", "negate", "match", "drop"].include?(field)

      re = Regexp.new(pattern)
      @patterns[field] << re
      @logger.debug(["grep: #{@type}/#{field}", pattern, re])
    end # @match.merge.each
  end # def register

  public
  def filter(event)
    if event.type != @type
      @logger.debug("grep: skipping type #{event.type} from #{event.source}")
      return
    end

    @logger.debug(["Running grep filter", event.to_hash, config])
    matches = 0
    @patterns.each do |field, regexes|
      if !event[field]
        @logger.debug(["Skipping match object, field not present", field,
                      event, event[field]])
        next
      end

      # For each match object, we have to match everything in order to
      # apply any fields/tags.
      match_count = 0
      match_want = 0
      regexes.each do |re|
        match_want += 1

        # Events without this field, with negate enabled, count as a match.
        if event[field].nil? and @negate == true
          match_count += 1
        end

        (event[field].is_a?(Array) ? event[field] : [event[field]]).each do |value|
          if @negate
            @logger.debug(["want negate match", re, value])
            next if re.match(value)
            @logger.debug(["grep not-matched (negate requsted)", { field => value }])
          else
            @logger.debug(["want match", re, value])
            next unless re.match(value)
            @logger.debug(["grep matched", { field => value }])
          end
          match_count += 1
          break
        end # each value in event[field]
      end # regexes.each

      if match_count == match_want
        matches += 1
        @logger.debug("matched all fields (#{match_count})")
      else
        @logger.debug("match block failed " \
                      "(#{match_count}/#{match_want} matches)")
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

    @logger.debug(["Event after grep filter", event.to_hash])
  end # def filter
end # class LogStash::Filters::Grep
