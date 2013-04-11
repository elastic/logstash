require "logstash/filters/base"
require "logstash/namespace"

# The prune filter is for pruning event data from @fileds based on whitelist/blacklist
# of field names or their values (names and values can also be regular expressions).

class LogStash::Filters::Prune < LogStash::Filters::Base
  config_name "prune"
  plugin_status "experimental"

  # Trigger whether configation fields and values should be interpolated for dynamic values.
  # Probably adds some performance overhead. Defaults to false.
  config :interpolate, :validate => :boolean, :default => false

  # Include only fields only if their names match specified regexps, default to empty list which means include everything.
  # 
  #     filter { 
  #       %PLUGIN% { 
  #         tags            => [ "apache-accesslog" ]
  #         whitelist_names => [ "method", "(referrer|status)", "${some}_field" ]
  #       }
  #     }
  config :whitelist_names, :validate => :array, :default => []

  # Exclude fields which names match specified regexps, by default exclude unresolved %{field} strings.
  #
  #     filter { 
  #       %PLUGIN% { 
  #         tags            => [ "apache-accesslog" ]
  #         blacklist_names => [ "method", "(referrer|status)", "${some}_field" ]
  #       }
  #     }
  config :blacklist_names, :validate => :array, :default => [ "%\{[^}]+\}" ]

  # Include specified fields only if their values match regexps.
  # 
  #     filter { 
  #       %PLUGIN% { 
  #         tags             => [ "apache-accesslog" ]
  #         whitelist_values => [ "uripath", "/index.php", method", "(GET|POST)", "status", "^[^2]" ]
  #       }
  #     }
  config :whitelist_values, :validate => :hash, :default => {}

  # Exclude specified fields if their values match regexps.
  #
  #     filter { 
  #       %PLUGIN% { 
  #         tags             => [ "apache-accesslog" ]
  #         blacklist_values => [ "uripath", "/index.php", "method", "(HEAD|OPTIONS)", "status", "^[^2]" ]
  #       }
  #     }
  config :blacklist_values, :validate => :hash, :default => {}

  public
  def register
    unless @interpolate
      @whitelist_names_regexp = Regexp.union(@whitelist_names.map {|x| Regexp.new(x)})
      @blacklist_names_regexp = Regexp.union(@blacklist_names.map {|x| Regexp.new(x)})
      @whitelist_values.each do |key, value|
        @whitelist_values[key] = Regexp.new(value)
      end
      @blacklist_values.each do |key, value|
        @blacklist_values[key] = Regexp.new(value)
      end
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    # We need to collect fields which needs to be remove ,and only in the end actually remove it
    # since then interpolation mode you can get unexpected results as fields with dynamic values will not match
    # since the fields to which they refer have already been removed.
    fields_to_remove = []

    unless @whitelist_names.empty?
      @whitelist_names_regexp = Regexp.union(@whitelist_names.map {|x| Regexp.new(event.sprintf(x))}) if @interpolate
      event.fields.each_key do |field|
        fields_to_remove << field unless field.match(@whitelist_names_regexp)
      end
    end

    unless @blacklist_names.empty?
      @blacklist_names_regexp = Regexp.union(@blacklist_names.map {|x| Regexp.new(event.sprintf(x))}) if @interpolate
      event.fields.each_key do |field|
        fields_to_remove << field if field.match(@blacklist_names_regexp)
      end
    end

    @whitelist_values.each do |key, value|
      if @interpolate
        key = event.sprintf(key)
        value = Regexp.new(event.sprintf(value))
      end
      fields_to_remove << key if event.fields[key] and not event.fields[key].match(value)
    end

    @blacklist_values.each do |key,value|
      if @interpolate
        key = event.sprintf(key)
        value = Regexp.new(event.sprintf(value))
      end
      fields_to_remove << key if event.fields[key] and event.fields[key].match(value)
    end

    fields_to_remove.each do |field|
      event.remove(field)
    end

    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Prune
