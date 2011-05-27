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
# <https://github.com/jordansissel/grok/blob/master/INSTALL>o
#
# Key dependencies:
#
# * libtokyocabinet > 1.4.6
# * libpcre >= 7.6
# * libevent >= 1.3 (though older versions may worK)
#
# Note:
# CentOS 5 ships with an ancient version of pcre that does not work with grok.
class LogStash::Filters::Grok < LogStash::Filters::Base
  config_name "grok"

  # Specify a pattern to parse with.
  # Multiple patterns is fine. First match breaks.
  config :pattern, :validate => :array, :required => true

  # Specify a path to a directory with grok pattern files in it
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
  config :patterns_dir, :validate => :array

  # Drop if matched. Note, this feature may not stay. It is preferable to combine
  # grok + grep filters to do parsing + dropping.
  #
  # requested in: googlecode/issue/26
  config :drop_if_match, :validate => :boolean, :default => false

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
    @@patterns_path += val.split(":")
  end

  @@grokpiles = Hash.new { |h, k| h[k] = [] }
  @@grokpiles_lock = Mutex.new

  public
  def register
    gem "jls-grok", ">=0.4.3"
    require "grok" # rubygem 'jls-grok'

    @pile = Grok::Pile.new
    @patterns_dir ||= []
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

    # Only filter events we are configured for
    if event.type != @type
      return
    end

    if @@grokpiles[event.type].length == 0
      @logger.debug("Skipping grok for event type=#{event.type} (no grokpiles defined)")
      return
    end

    if !event.message.is_a?(Array)
      messages = [event.message]
    else
      messages = event.message
    end

    messages.each do |message|
      @logger.debug(["Running grok filter", event])

      @@grokpiles[event.type].each do |pile|
        @logger.debug(["Trying pattern for type #{event.type}", pile])
        grok, match = @pile.match(message)
        @logger.debug(["Result", { :grok => grok, :match => match }])
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

          if @named_captures_only && key.upcase == key
            @logger.debug("Skipping capture '#{key}' since it is not a named capture and named_captures_only is true.")
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
        # In some cases I have seen 'file.each' yield lines with newlines at
        # the end. I don't know if this is a bug or intentional, but we need
        # to chomp it.
        name, pattern = line.chomp.split(/\s+/, 2)
        @logger.debug "Adding pattern '#{name}' from file #{file}"
        @logger.debug name => pattern
        @pile.add_pattern(name, pattern)
      end
    else
      @pile.add_patterns_from_file(file)
    end
  end # def add_patterns
end # class LogStash::Filters::Grok
