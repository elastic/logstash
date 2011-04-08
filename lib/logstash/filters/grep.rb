require "logstash/filters/base"
require "logstash/namespace"

# Grep filter. Useful for dropping events you don't want to pass.
#
# Events not matched are dropped. If 'negate' is set to true (defaults false),
# then matching events are dropped.
class LogStash::Filters::Grep < LogStash::Filters::Base

  config_name "grep"

  # Negate the match. Similar to 'grep -v'
  #
  # If this is set to true, then any positive matches will result in the
  # event being cancelled and dropped. Non-matching will be allowed
  # through.
  config :negate, :validate => :boolean, :default => false

  # A hash of matches of field => value
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
      next if ["add_tag", "add_field", "type", "negate", "match"].include?(field)

      re = Regexp.new(pattern)
      @patterns[field] << re
      @logger.debug(["grep: #{@type}/#{field}", pattern, re])
    end # @config.each
  end # def register

  public
  def filter(event)
    if event.type != @type
      @logger.debug("grep: skipping type #{event.type} from #{event.source}")
      event.cancel
      return
    end

    @logger.debug(["Running grep filter", event.to_hash, config])
    matched = false
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
            @logger.debug("want negate match")
            next if re.match(value)
            @logger.debug(["grep not-matched (negate requsted)", { field => value }])
          else
            @logger.debug(["trying regex", re, value])
            next unless re.match(value)
            @logger.debug(["grep matched", { field => value }])
          end
          match_count += 1
          break
        end # each value in event[field]
      end # regexes.each

      if match_count == match_want
        matched = true
        @logger.debug("matched all fields (#{match_count})")
      else
        @logger.debug("match block failed " \
                      "(#{match_count}/#{match_want} matches)")
        event.cancel
      end # match["match"].each
    end # config.each

    if not matched || event.cancelled?
      @logger.debug("grep: dropping event, no matches")
      event.cancel
      return
    end

    @logger.debug(["Event after grep filter", event.to_hash])

    if !event.cancelled?
      filter_matched(event)
    end
  end # def filter
end # class LogStash::Filters::Grep
