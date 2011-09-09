require "logstash/filters/base"
require "logstash/namespace"
require "set"

# Parse arbitrary text and structure it.
# Grok is currently the best way in logstash to parse crappy unstructured log
# data (like syslog or apache logs) into something structured and queryable.
#
# This filter requires you have libgrok installed.
#
# You can find libgrok here: 
# <http://code.google.com/p/semicomplete/wiki/Grok>
#
# Compile/install notes can be found in the INSTALL file of the
# grok tarball, or here: 
# <https://github.com/jordansissel/grok/blob/master/INSTALL>
#
# Key dependencies:
#
# * libtokyocabinet > 1.4.6
# * libpcre >= 7.6
# * libevent >= 1.3 (though older versions may worK)
#
# Feature requirements:
#
# * Int/float coercion requires >= 1.20110223.*
# * In-line pattern definitions >= 1.20110630.*
#
# Note:
# CentOS 5 ships with an ancient version of pcre that does not work with grok.
class LogStash::Filters::Grok < LogStash::Filters::Base
  config_name "grok"

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
  config :named_captures_only, :validate => :boolean, :default => false

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
  def register
    gem "jls-grok", ">=0.4.3"
    require "grok-pure" # rubygem 'jls-grok'

    @patternfiles = []
    @patterns_dir += @@patterns_path.to_a
    @logger.info("Grok patterns path: #{@patterns_dir.join(":")}")
    @patterns_dir.each do |path|
      # Can't read relative paths from jars, try to normalize away '../'
      while path =~ /file:\/.*\.jar!.*\/\.\.\//
        # replace /foo/bar/../baz => /foo/baz
        path = path.gsub(/[^\/]+\/\.\.\//, "")
        @logger.debug "In-jar path to read: #{path}"
      end

      if File.directory?(path)
        path = File.join(path, "*")
      end

      Dir.glob(path).each do |file|
        @logger.info("Grok loading patterns from #{file}")
        @patternfiles << file
      end
    end

    @patterns = Hash.new { |h,k| h[k] = [] }
    
    @logger.info(:match => @match)

    @match["@message"] ||= []
    @match["@message"] += @pattern if @pattern # the config 'pattern' value (array)

    # TODO(sissel): Hash.merge  actually overrides, not merges arrays. 
    # Work around it by implementing our own?
    # TODO(sissel): Check if 'match' is empty?
    @match.merge(@config).each do |field, patterns|
      # Skip known config names
      next if ["add_tag", "add_field", "type", "match", "patterns_dir",
               "drop_if_match", "named_captures_only", "pattern",
               "break_on_match" ].include?(field)
      patterns = [patterns] if patterns.is_a?(String)

      if !@patterns.include?(field)
        @patterns[field] = Grok::Pile.new 
        add_patterns_from_files(@patternfiles, @patterns[field])
      end
      @logger.info(["Grok compile", { :field => field, :patterns => patterns }])
      patterns.each do |pattern|
        @logger.debug(["regexp: #{@type}/#{field}", pattern])
        @patterns[field].compile(pattern)
      end
    end # @config.each
  end # def register

  public
  def filter(event)
    # parse it with grok
    matched = false

    # Only filter events we are configured for
    if event.type != @type
      return
    end

    if @type != event.type 
      @logger.debug("Skipping grok for event type=#{event.type} (wanted '#{@type}')")
      return
    end

    @logger.debug(["Running grok filter", event])
    done = false
    @patterns.each do |field, pile|
      break if done
      if !event[field]
        @logger.debug(["Skipping match object, field not present", field,
                      event, event[field]])
        next
      end

      @logger.debug(["Trying pattern for type #{event.type}", { :pile => pile, :field => field }])
      (event[field].is_a?(Array) ? event[field] : [event[field]]).each do |fieldvalue|
        grok, match = pile.match(fieldvalue)
        next unless match
        matched = true
        done = true if @break_on_match

        match.each_capture do |key, value|
          type_coerce = nil
          if key.include?(":")
            name, key, type_coerce = key.split(":")
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

          if fieldvalue == value and field == "@message"
            # Skip patterns that match the entire message
            @logger.debug("Skipping capture '#{key}' since it matches the whole line.")
            next
          end

          if @named_captures_only && key =~ /^[A-Z]+/
            @logger.debug("Skipping capture '#{key}' since it is not a named " \
                          "capture and named_captures_only is true.")
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
        end # match.each_capture
        
        #The following should probably be governed by a configuration option
        #If there is a single value on an array, set the key to the single value
        event.fields.each { |k, v| event.fields[k] = v.first if v.is_a?(Array) && v.length == 1 }
        #Also, empty fields are forced to be empty, not a null array
        event.fields.each { |k, v| event.fields[k] = nil if v.is_a?(Array) && v.length == 0 }

        filter_matched(event)
      end # event[field]
    end # patterns.each

    if !matched
      # Tag this event if we can't parse it. We can use this later to
      # reparse+reindex logs if we improve the patterns given .
      event.tags << "_grokparsefailure"
    end

    @logger.debug(["Event now: ", event.to_hash])
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
        @logger.debug "Adding pattern '#{name}' from file #{path}"
        @logger.debug name => pattern
        pile.add_pattern(name, pattern)
      end
    else
      pile.add_patterns_from_file(path)
    end
  end # def add_patterns
end # class LogStash::Filters::Grok
