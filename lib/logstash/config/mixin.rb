# encoding: utf-8

require "logstash/namespace"
require "logstash/config/registry"
require "logstash/logging"
require "logstash/util/password"
require "logstash/version"
require "i18n"

# This module is meant as a mixin to classes wishing to be configurable from
# config files
#
# The idea is that you can do this:
#
# class Foo < LogStash::Config
#   # Add config file settings
#   config "path" => ...
#   config "tag" => ...
#
#   # Add global flags (becomes --foo-bar)
#   flag "bar" => ...
# end
#
# And the config file should let you do:
#
# foo {
#   "path" => ...
#   "tag" => ...
# }
#
module LogStash::Config::Mixin
  attr_accessor :config
  attr_accessor :original_params

  CONFIGSORT = {
    Symbol => 0,
    String => 0,
    Regexp => 100,
  }

  # This method is called when someone does 'include LogStash::Config'
  def self.included(base)
    # Add the DSL methods to the 'base' given.
    base.extend(LogStash::Config::Mixin::DSL)
  end

  def config_init(params)
    # Validation will modify the values inside params if necessary.
    # For example: converting a string to a number, etc.
    
    # Keep a copy of the original config params so that we can later
    # differentiate between explicit configuration and implicit (default)
    # configuration.
    @original_params = params.clone
    
    # store the plugin type, turns LogStash::Inputs::Base into 'input'
    @plugin_type = self.class.ancestors.find { |a| a.name =~ /::Base$/ }.config_name

    # warn about deprecated variable use
    params.each do |name, value|
      opts = self.class.get_config[name]
      if opts && opts[:deprecated]
        extra = opts[:deprecated].is_a?(String) ? opts[:deprecated] : ""
        extra.gsub!("%PLUGIN%", self.class.config_name)
        @logger.warn("You are using a deprecated config setting " +
                     "#{name.inspect} set in #{self.class.config_name}. " +
                     "Deprecated settings will continue to work, " +
                     "but are scheduled for removal from logstash " +
                     "in the future. #{extra} If you have any questions " +
                     "about this, please visit the #logstash channel " +
                     "on freenode irc.", :name => name, :plugin => self)
      end
    end

    # Set defaults from 'config :foo, :default => somevalue'
    self.class.get_config.each do |name, opts|
      next if params.include?(name.to_s)
      if opts.include?(:default) and (name.is_a?(Symbol) or name.is_a?(String))
        # default values should be cloned if possible
        # cloning prevents 
        case opts[:default]
          when FalseClass, TrueClass, NilClass, Numeric
            params[name.to_s] = opts[:default]
          else
            params[name.to_s] = opts[:default].clone
        end
      end

      # Allow plugins to override default values of config settings
      if self.class.default?(name)
        params[name.to_s] = self.class.get_default(name)
      end
    end

    if !self.class.validate(params)
      raise LogStash::ConfigurationError,
        I18n.t("logstash.agent.configuration.invalid_plugin_settings")
    end

    # set instance variables like '@foo'  for each config value given.
    params.each do |key, value|
      next if key[0, 1] == "@"

      # Set this key as an instance variable only if it doesn't start with an '@'
      @logger.debug("config #{self.class.name}/@#{key} = #{value.inspect}")
      instance_variable_set("@#{key}", value)
    end

    @config = params
  end # def config_init

  module DSL
    attr_accessor :flags

    # If name is given, set the name and return it.
    # If no name given (nil), return the current name.
    def config_name(name=nil)
      @config_name = name if !name.nil?
      LogStash::Config::Registry.registry[@config_name] = self
      return @config_name
    end

    def plugin_status(status=nil)
      milestone(status)
    end

    def milestone(m=nil)
      @milestone = m if !m.nil?
      return @milestone
    end

    # Define a new configuration setting
    def config(name, opts={})
      @config ||= Hash.new
      # TODO(sissel): verify 'name' is of type String, Symbol, or Regexp

      name = name.to_s if name.is_a?(Symbol)
      @config[name] = opts  # ok if this is empty

      if name.is_a?(String)
        define_method(name) { instance_variable_get("@#{name}") }
        define_method("#{name}=") { |v| instance_variable_set("@#{name}", v) }
      end
    end # def config

    def default(name, value)
      @defaults ||= {}
      @defaults[name.to_s] = value
    end

    def get_config
      return @config
    end # def get_config

    def get_default(name)
      return @defaults && @defaults[name]
    end

    def default?(name)
      return @defaults && @defaults.include?(name)
    end

    def options(opts)
      # add any options from this class
      prefix = self.name.split("::").last.downcase
      @flags.each do |flag|
        flagpart = flag[:args].first.gsub(/^--/,"")
        # TODO(sissel): logger things here could help debugging.

        opts.on("--#{prefix}-#{flagpart}", *flag[:args][1..-1], &flag[:block])
      end
    end # def options

    # This is called whenever someone subclasses a class that has this mixin.
    def inherited(subclass)
      # Copy our parent's config to a subclass.
      # This method is invoked whenever someone subclasses us, like:
      # class Foo < Bar ...
      subconfig = Hash.new
      if !@config.nil?
        @config.each do |key, val|
          subconfig[key] = val
        end
      end
      subclass.instance_variable_set("@config", subconfig)
      @@milestone_notice_given = false
    end # def inherited

    def validate(params)
      @plugin_name = config_name
      @plugin_type = ancestors.find { |a| a.name =~ /::Base$/ }.config_name
      @logger = Cabin::Channel.get(LogStash)
      is_valid = true

      is_valid &&= validate_milestone
      is_valid &&= validate_check_invalid_parameter_names(params)
      is_valid &&= validate_check_required_parameter_names(params)
      is_valid &&= validate_check_parameter_values(params)

      return is_valid
    end # def validate

    def validate_milestone
      return true if @@milestone_notice_given
      docmsg = "For more information about plugin milestones, see http://logstash.net/docs/#{LOGSTASH_VERSION}/plugin-milestones "
      plugin_type = ancestors.find { |a| a.name =~ /::Base$/ }.config_name
      case @milestone
        when 0,1,2
          @logger.warn(I18n.t("logstash.plugin.milestone.#{@milestone}", 
                              :type => plugin_type, :name => @config_name,
                              :LOGSTASH_VERSION => LOGSTASH_VERSION))
        when 3
          # No message to log for milestone 3 plugins.
        when nil
          raise "#{@config_name} must set a milestone. #{docmsg}"
        else
          raise "#{@config_name} set an invalid plugin status #{@milestone}. Valid values are 0, 1, 2, or 3. #{docmsg}"
      end
      @@milestone_notice_given = true
      return true
    end

    def validate_check_invalid_parameter_names(params)
      invalid_params = params.keys
      # Filter out parameters that match regexp keys.
      # These are defined in plugins like this:
      #   config /foo.*/ => ...
      @config.each_key do |config_key|
        if config_key.is_a?(Regexp)
          invalid_params.reject! { |k| k =~ config_key }
        elsif config_key.is_a?(String)
          invalid_params.reject! { |k| k == config_key }
        end
      end

      if invalid_params.size > 0
        invalid_params.each do |name|
          @logger.error("Unknown setting '#{name}' for #{@plugin_name}")
        end
        return false
      end # if invalid_params.size > 0
      return true
    end # def validate_check_invalid_parameter_names

    def validate_check_required_parameter_names(params)
      is_valid = true

      @config.each do |config_key, config|
        next unless config[:required]

        if config_key.is_a?(Regexp)
          next if params.keys.select { |k| k =~ config_key }.length > 0
        elsif config_key.is_a?(String)
          next if params.keys.member?(config_key)
        end
        @logger.error(I18n.t("logstash.agent.configuration.setting_missing",
                             :setting => config_key, :plugin => @plugin_name,
                             :type => @plugin_type))
        is_valid = false
      end

      return is_valid
    end

    def validate_check_parameter_values(params)
      # Filter out parametrs that match regexp keys.
      # These are defined in plugins like this:
      #   config /foo.*/ => ... 
      is_valid = true

      params.each do |key, value|
        @config.keys.each do |config_key|
          next unless (config_key.is_a?(Regexp) && key =~ config_key) \
                      || (config_key.is_a?(String) && key == config_key)
          config_val = @config[config_key][:validate]
          #puts "  Key matches."
          success, result = validate_value(value, config_val)
          if success 
            # Accept coerced value if success
            # Used for converting values in the config to proper objects.
            params[key] = result if !result.nil?
          else
            @logger.error(I18n.t("logstash.agent.configuration.setting_invalid",
                                 :plugin => @plugin_name, :type => @plugin_type,
                                 :setting => key, :value => value.inspect,
                                 :value_type => config_val,
                                 :note => result))
          end
          #puts "Result: #{key} / #{result.inspect} / #{success}"
          is_valid &&= success

          break # done with this param key
        end # config.each
      end # params.each

      return is_valid
    end # def validate_check_parameter_values

    def validator_find(key)
      @config.each do |config_key, config_val|
        if (config_key.is_a?(Regexp) && key =~ config_key) \
           || (config_key.is_a?(String) && key == config_key)
          return config_val
        end
      end # @config.each
      return nil
    end

    def validate_value(value, validator)
      # Validator comes from the 'config' pieces of plugins.
      # They look like this
      #   config :mykey => lambda do |value| ... end
      # (see LogStash::Inputs::File for example)
      result = nil

      if validator.nil?
        return true
      elsif validator.is_a?(Array)
        value = [*value]
        if value.size > 1
          return false, "Expected one of #{validator.inspect}, got #{value.inspect}"
        end

        if !validator.include?(value.first)
          return false, "Expected one of #{validator.inspect}, got #{value.inspect}"
        end
        result = value.first
      elsif validator.is_a?(Symbol)
        # TODO(sissel): Factor this out into a coersion method?
        # TODO(sissel): Document this stuff.
        value = hash_or_array(value)

        case validator
          when :codec
            if value.first.is_a?(String)
              value = LogStash::Plugin.lookup("codec", value.first).new
              return true, value
            else
              value = value.first
              return true, value
            end
          when :hash
            if value.is_a?(Hash)
              return true, value
            end

            if value.size % 2 == 1
              return false, "This field must contain an even number of items, got #{value.size}"
            end

            # Convert the array the config parser produces into a hash.
            result = {}
            value.each_slice(2) do |key, value|
              entry = result[key]
              if entry.nil?
                result[key] = value
              else
                if entry.is_a?(Array)
                  entry << value
                else
                  result[key] = [entry, value]
                end
              end
            end
          when :array
            result = value
          when :string
            if value.size > 1 # only one value wanted
              return false, "Expected string, got #{value.inspect}"
            end
            result = value.first
          when :number
            if value.size > 1 # only one value wanted
              return false, "Expected number, got #{value.inspect} (type #{value.class})"
            end

            v = value.first
            case v
              when Numeric
                result = v
              when String
                if v.to_s.to_f.to_s != v.to_s \
                   && v.to_s.to_i.to_s != v.to_s
                  return false, "Expected number, got #{v.inspect} (type #{v})"
                end
                if v.include?(".")
                  # decimal value, use float.
                  result = v.to_f
                else
                  result = v.to_i
                end
            end # case v
          when :boolean
            if value.size > 1 # only one value wanted
              return false, "Expected boolean, got #{value.inspect}"
            end

            bool_value = value.first
            if !!bool_value == bool_value
              # is_a does not work for booleans
              # we have Boolean and not a string
              result = bool_value
            else
              if bool_value !~ /^(true|false)$/
                return false, "Expected boolean 'true' or 'false', got #{bool_value.inspect}"
              end

              result = (bool_value == "true")
            end
          when :ipaddr
            if value.size > 1 # only one value wanted
              return false, "Expected IPaddr, got #{value.inspect}"
            end

            octets = value.split(".")
            if octets.length != 4
              return false, "Expected IPaddr, got #{value.inspect}"
            end
            octets.each do |o|
              if o.to_i < 0 or o.to_i > 255
                return false, "Expected IPaddr, got #{value.inspect}"
              end
            end
            result = value.first
          when :password
            if value.size > 1
              return false, "Expected password (one value), got #{value.size} values?"
            end

            result = ::LogStash::Util::Password.new(value.first)
          when :path
            if value.size > 1 # Only 1 value wanted
              return false, "Expected path (one value), got #{value.size} values?"
            end

            # Paths must be absolute
            #if !Pathname.new(value.first).absolute?
              #return false, "Require absolute path, got relative path #{value.first}?"
            #end

            if !File.exists?(value.first) # Check if the file exists
              return false, "File does not exist or cannot be opened #{value.first}"
            end

            result = value.first
          else
            return false, "Unknown validator symbol #{validator}"
        end # case validator
      else
        return false, "Unknown validator #{validator.class}"
      end

      # Return the validator for later use, like with type coercion.
      return true, result
    end # def validate_value

    def hash_or_array(value)
      if !value.is_a?(Hash)
        value = [*value] # coerce scalar to array if necessary
      end
      return value
    end
  end # module LogStash::Config::DSL
end # module LogStash::Config
