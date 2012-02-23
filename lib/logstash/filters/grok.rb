require "logstash/filters/base"
require "logstash/namespace"
require "set"

# Parse arbitrary text and structure it.
# Grok is currently the best way in logstash to parse crappy unstructured log
# data (like syslog or apache logs) into something structured and queryable.
#
# Grok allows you to match text without needing to be a regular expressions
# ninja. Logstash ships with about 120 patterns by default. You can add
# your own trivially. (See the patterns_dir setting)
class LogStash::Filters::Grok < LogStash::Filters::Base
  config_name "grok"
  plugin_status "stable"

  # Specify a pattern to parse with. This will match the '@message' field.
  #
  # If you want to match other fields than @message, use the 'match' setting.
  # Multiple patterns is fine.
  config :pattern, :validate => :array

  # Specify a path to a directory with grok pattern files in it
  # A hash of matches of field => value
  config :match, :validate => :hash, :default => {}

  # Any existing field name can be used as a config name here for matching
  # against.
  #
  #     # this config:
  #     foo => "some pattern"
  #
  #     # same as:
  #     match => [ "foo", "some pattern" ]
  config /[A-Za-z0-9_-]+/, :validate => :string

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
  #
  # requested in: googlecode/issue/26
  config :drop_if_match, :validate => :boolean, :default => false

  # Break on first match. The first successful match by grok will result in the
  # filter being finished. If you want grok to try all patterns (maybe you are
  # parsing different things), then set this to false.
  config :break_on_match, :validate => :boolean, :default => true

  # If true, only store named captures from grok.
  config :named_captures_only, :validate => :boolean, :default => true

  # If true, keep empty captures as event fields.
  config :keep_empty_captures, :validate => :boolean, :default => false

  # TODO(sissel): Add this feature?
  # When disabled, any pattern that matches the entire string will not be set.
  # This is useful if you have named patterns like COMBINEDAPACHELOG that will
  # match entire events and you really don't want to add a field
  # 'COMBINEDAPACHELOG' that is set to the whole event line.
  #config :capture_full_match_patterns, :validate => :boolean, :default => false

  # Detect if we are running from a jarfile, pick the right path.
  @@patterns_path ||= Set.new
  if __FILE__ =~ /file:\/.*\.jar!.*/
    @@patterns_path += ["#{File.dirname(__FILE__)}/../../patterns/*"]
  else
    @@patterns_path += ["#{File.dirname(__FILE__)}/../../../patterns/*"]
  end

  # This flag becomes "--grok-patterns-path"
  flag("--patterns-path PATH", "Colon-delimited path of patterns to load") do |val|
    #@logger.info("Adding patterns path: #{val}")
    @@patterns_path += val.split(":")
  end

  public
  def initialize(params)
    super(params)
    @match["@message"] ||= []
    @match["@message"] += @pattern if @pattern # the config 'pattern' value (array)
  end

  public
  def register
    require "grok-pure" # rubygem 'jls-grok'

    @patternfiles = []
    @patterns_dir += @@patterns_path.to_a
    @logger.info("Grok patterns path", :patterns_dir => @patterns_dir)
    @patterns_dir.each do |path|
      # Can't read relative paths from jars, try to normalize away '../'
      while path =~ /file:\/.*\.jar!.*\/\.\.\//
        # replace /foo/bar/../baz => /foo/baz
        path = path.gsub(/[^\/]+\/\.\.\//, "")
        @logger.debug("In-jar path to read", :path => path)
      end

      if File.directory?(path)
        path = File.join(path, "*")
      end

      Dir.glob(path).each do |file|
        @logger.info("Grok loading patterns from file", :path => file)
        @patternfiles << file
      end
    end

    @patterns = Hash.new { |h,k| h[k] = [] }

    @logger.info("Match data", :match => @match)

    # TODO(sissel): Hash.merge  actually overrides, not merges arrays.
    # Work around it by implementing our own?
    # TODO(sissel): Check if 'match' is empty?
    @match.merge(@config).each do |field, patterns|
      # Skip known config names
      next if (RESERVED + ["match", "patterns_dir",
               "drop_if_match", "named_captures_only", "pattern",
               "keep_empty_captures", "break_on_match"]).include?(field)
      patterns = [patterns] if patterns.is_a?(String)

      if !@patterns.include?(field)
        @patterns[field] = Grok::Pile.new
        #@patterns[field].logger = @logger

        add_patterns_from_files(@patternfiles, @patterns[field])
      end
      @logger.info("Grok compile", :field => field, :patterns => patterns)
      patterns.each do |pattern|
        @logger.debug("regexp: #{@type}/#{field}", :pattern => pattern)
        @patterns[field].compile(pattern)
      end
    end # @config.each
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    # parse it with grok
    matched = false

    @logger.debug("Running grok filter", :event => event);
    done = false
    @patterns.each do |field, pile|
      break if done
      if !event[field]
        @logger.debug("Skipping match object, field not present", 
                      :field => field, :event => event)
        next
      end

      @logger.debug("Trying pattern", :pile => pile, :field => field )
      (event[field].is_a?(Array) ? event[field] : [event[field]]).each do |fieldvalue|
        grok, match = pile.match(fieldvalue)
        next unless match
        matched = true
        done = true if @break_on_match

        match.each_capture do |key, value|
          type_coerce = nil
          is_named = false
          if key.include?(":")
            name, key, type_coerce = key.split(":")
            is_named = true
          end

          # http://code.google.com/p/logstash/issues/detail?id=45
          # Permit typing of captures by giving an additional colon and a type,
          # like: %{FOO:name:int} for int coercion.
          if type_coerce
            @logger.info("Match type coerce: #{type_coerce}")
            @logger.info("Patt: #{grok.pattern}")
          end

          case type_coerce
            when "int"
              value = value.to_i
            when "float"
              value = value.to_f
          end

          # Special casing to skip captures that represent the entire log message.
          if fieldvalue == value and field == "@message"
            # Skip patterns that match the entire message
            @logger.debug("Skipping capture since it matches the whole line.", :field => key)
            next
          end

          if @named_captures_only && !is_named
            @logger.debug("Skipping capture since it is not a named " \
                          "capture and named_captures_only is true.", :field => key)
            next
          end

          if event.fields[key].is_a?(String)
            event.fields[key] = [event.fields[key]]
          end

          if @keep_empty_captures && event.fields[key].nil?
            event.fields[key] = []
          end

          # If value is not nil, or responds to empty and is not empty, add the
          # value to the event.
          if !value.nil? && (!value.empty? rescue true)
            event.fields[key] ||= []
            event.fields[key] << value
          end
        end # match.each_capture

        filter_matched(event)
      end # event[field]
    end # patterns.each

    if !matched
      # Tag this event if we can't parse it. We can use this later to
      # reparse+reindex logs if we improve the patterns given .
      event.tags << "_grokparsefailure"
    end

    @logger.debug("Event now: ", :event => event)
  end # def filter

  private
  def add_patterns_from_files(paths, pile)
    paths.each { |path| add_patterns_from_file(path, pile) }
  end

  private
  def add_patterns_from_file(path, pile)
    # Check if the file path is a jar, if so, we'll have to read it ourselves
    # since libgrok won't know what to do with it.
    if path =~ /file:\/.*\.jar!.*/
      File.new(path).each do |line|
        next if line =~ /^(?:\s*#|\s*$)/
        # In some cases I have seen 'file.each' yield lines with newlines at
        # the end. I don't know if this is a bug or intentional, but we need
        # to chomp it.
        name, pattern = line.chomp.split(/\s+/, 2)
        @logger.debug("Adding pattern from file", :name => name,
                      :pattern => pattern, :path => path)
        pile.add_pattern(name, pattern)
      end
    else
      pile.add_patterns_from_file(path)
    end
  end # def add_patterns
end # class LogStash::Filters::Grok
