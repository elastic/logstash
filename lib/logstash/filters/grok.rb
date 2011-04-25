require "logstash/filters/base"
require "logstash/namespace"

# Parse arbitrary text and structure it.
#
# Use grok 
class LogStash::Filters::Grok < LogStash::Filters::Base
  config_name "grok"

  # Specify a pattern to parse with.
  # Multiple patterns is fine. First match breaks.
  config :pattern, :validate => :array, :required => true

  # Specify a path to a directory with grok pattern files in it
  # Pattern files are plain text with format:
  #   NAME PATTERN
  #
  # For example:
  #   NUMBER \d+
  config :patterns_dir, :validate => :array

  # Drop if matched. Note, this feature may not stay. It is preferable to combine
  # grok + grep filters to do parsing + dropping.
  #
  # requested in: googlecode/issue/26
  config :drop_if_match, :validate => :boolean, :default => false

  class << self
    attr_accessor :patterns_dir
  end

  # Detect if we are running from a jarfile, pick the right path.
  if __FILE__ =~ /file:\/.*\.jar!.*/
    self.patterns_dir = ["#{File.dirname(__FILE__)}/../../patterns/*"]
  else
    self.patterns_dir = ["#{File.dirname(__FILE__)}/../../../patterns/*"]
  end

  # This flag becomes "--grok-patterns-path"
  flag("--patterns-path PATH", "Colon-delimited path of patterns to load") do |val|
    @patterns_dir += val.split(":")
  end

  @@grokpiles = Hash.new { |h, k| h[k] = [] }
  @@grokpiles_lock = Mutex.new

  public
  def register
    gem "jls-grok", ">=0.4.3"
    require "grok" # rubygem 'jls-grok'

    @pile = Grok::Pile.new
    @logger.info("Grok patterns paths: #{self.class.patterns_dir.inspect}")
    self.class.patterns_dir.each do |path|
      # Can't read relative paths from jars, try to normalize away '../'
      while path =~ /file:\/.*\.jar!.*\/\.\.\//
        # replace /foo/bar/../baz => /foo/baz
        path.gsub!(/[^\/]+\/\.\.\//, "")
        @logger.debug "In-jar path to read: #{path}"
      end

      if File.directory?(path)
        path = File.join(path, "*")
      end

      Dir.glob(path).each do |file|
        @logger.info("Grok loading patterns from #{file}")
        add_patterns_from_file(file)
      end
    end

    @pattern.each do |pattern|
      groks = @pile.compile(pattern)
      @logger.debug(["Compiled pattern", pattern, groks[-1].expanded_pattern])
    end

    @@grokpiles_lock.synchronize do
      @@grokpiles[@type] << @pile
    end
  end # def register

  public
  def filter(event)
    # parse it with grok
    match = false

    if !event.message.is_a?(Array)
      messages = [event.message]
    else
      messages = event.message
    end

    messages.each do |message|
      @logger.debug(["Running grok filter", event])
      @@grokpiles[event.type].each do |pile|
        grok, match = @pile.match(message)
        break if match
      end

      if match
        match.each_capture do |key, value|
          match_type = nil
          if key.include?(":")
            name, key, match_type = key.split(":")
          end

          # http://code.google.com/p/logstash/issues/detail?id=45
          # Permit typing of captures by giving an additional colon and a type,
          # like: %{FOO:name:int} for int coercion.
          case match_type
            when "int"
              value = value.to_i
            when "float"
              value = value.to_f
          end

          if event.message == value
            # Skip patterns that match the entire line
            @logger.debug("Skipping capture '#{key}' since it matches the whole line.")
            next
          end

          if event.fields[key].is_a?(String)
            event.fields[key] = [event.fields[key]]
          elsif event.fields[key] == nil
            event.fields[key] = []
          end

          # If value is not nil, or responds to empty and is not empty, add the
          # value to the event.
          if !value.nil? && (!value.empty? rescue true)
            event.fields[key] << value
          end
        end
        filter_matched(event)
      else
        # Tag this event if we can't parse it. We can use this later to
        # reparse+reindex logs if we improve the patterns given .
        event.tags << "_grokparsefailure"
      end
    end # message.each

    #if !event.cancelled?
      #filter_matched(event)
    #end
    @logger.debug(["Event now: ", event.to_hash])
  end # def filter

  private
  def add_patterns_from_file(file)
    # Check if the file path is a jar, if so, we'll have to read it ourselves
    # since libgrok won't know what to do with it.
    if file =~ /file:\/.*\.jar!.*/
      File.new(file).each do |line|
        next if line =~ /^(?:\s*#|\s*$)/
        name, pattern = line.split(/\s+/, 2)
        @logger.debug "Adding pattern '#{name}' from file #{file}"
        @pile.add_pattern(name, pattern)
      end
    else
      @pile.add_patterns_from_file(file)
    end
  end # def add_patterns
end # class LogStash::Filters::Grok
