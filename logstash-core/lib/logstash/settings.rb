# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "fileutils"
require "delegate"

require "logstash/util/byte_value"
require "logstash/util/substitution_variables"
require "logstash/util/time_value"
require "i18n"

module LogStash
  class Settings

    include LogStash::Util::SubstitutionVariables
    include LogStash::Util::Loggable

    # The `LOGGABLE_PROXY` is included into `LogStash::Setting` to make all
    # settings-related logs and deprecations come from the same logger.
    LOGGABLE_PROXY = Module.new do
      define_method(:logger) { Settings.logger }
      define_method(:deprecation_logger) { Settings.deprecation_logger }

      def self.included(base)
        base.extend(self)
      end
    end

    # there are settings that the pipeline uses and can be changed per pipeline instance
    PIPELINE_SETTINGS_WHITE_LIST = [
      "config.debug",
      "config.support_escapes",
      "config.reload.automatic",
      "config.reload.interval",
      "config.string",
      "dead_letter_queue.enable",
      "dead_letter_queue.flush_interval",
      "dead_letter_queue.max_bytes",
      "dead_letter_queue.storage_policy",
      "dead_letter_queue.retain.age",
      "metric.collect",
      "pipeline.plugin_classloaders",
      "path.config",
      "path.dead_letter_queue",
      "path.queue",
      "pipeline.batch.delay",
      "pipeline.batch.size",
      "pipeline.id",
      "pipeline.reloadable",
      "pipeline.system",
      "pipeline.workers",
      "pipeline.ordered",
      "pipeline.ecs_compatibility",
      "queue.checkpoint.acks",
      "queue.checkpoint.interval",
      "queue.checkpoint.writes",
      "queue.checkpoint.retry",
      "queue.drain",
      "queue.max_bytes",
      "queue.max_events",
      "queue.page_capacity",
      "queue.type",
    ]

    def initialize
      @settings = {}
      # Theses settings were loaded from the yaml file
      # but we didn't find any settings to validate them,
      # lets keep them around until we do `validate_all` at that
      # time universal plugins could have added new settings.
      @transient_settings = {}
    end

    def register(setting)
      return setting.map { |s| register(s) } if setting.kind_of?(Array)

      if @settings.key?(setting.name)
        raise ArgumentError.new("Setting \"#{setting.name}\" has already been registered as #{setting.inspect}")
      else
        @settings[setting.name] = setting
      end
    end

    def registered?(setting_name)
       @settings.key?(setting_name)
    end

    def get_setting(setting_name)
      setting = @settings[setting_name]
      raise ArgumentError.new("Setting \"#{setting_name}\" doesn't exist. Please check if you haven't made a typo.") if setting.nil?
      setting
    end

    def get_subset(setting_regexp)
      regexp = setting_regexp.is_a?(Regexp) ? setting_regexp : Regexp.new(setting_regexp)
      settings = self.class.new
      @settings.each do |setting_name, setting|
        next unless setting_name.match(regexp)
        settings.register(setting.clone)
      end
      settings
    end

    def names
      @settings.keys
    end

    def set?(setting_name)
      get_setting(setting_name).set?
    end

    def clone(*args)
      get_subset(".*")
    end
    alias_method :dup, :clone

    def get_default(setting_name)
      get_setting(setting_name).default
    end

    def get_value(setting_name)
      get_setting(setting_name).value
    end
    alias_method :get, :get_value

    def set_value(setting_name, value, graceful = false)
      get_setting(setting_name).set(value)
    rescue ArgumentError => e
      if graceful
        @transient_settings[setting_name] = value
      else
        raise e
      end
    end
    alias_method :set, :set_value

    def to_hash
      hash = {}
      @settings.each do |name, setting|
        next if setting.kind_of? Setting::DeprecatedAlias
        hash[name] = setting.value
      end
      hash
    end

    def merge(hash, graceful = false)
      hash.each {|key, value| set_value(key, value, graceful) }
      self
    end

    def merge_pipeline_settings(hash, graceful = false)
      hash.each do |key, _|
        unless PIPELINE_SETTINGS_WHITE_LIST.include?(key)
          raise ArgumentError.new("Only pipeline related settings are expected. Received \"#{key}\". Allowed settings: #{PIPELINE_SETTINGS_WHITE_LIST}")
        end
      end
      merge(hash, graceful)
    end

    def format_settings
      output = []
      output << "-------- Logstash Settings (* means modified) ---------"
      @settings.each do |setting_name, setting|
        setting.format(output)
      end
      output << "--------------- Logstash Settings -------------------"
      output
    end

    def reset
      @settings.values.each(&:reset)
    end

    def from_yaml(yaml_path, file_name = "logstash.yml")
      settings = read_yaml(::File.join(yaml_path, file_name))
      self.merge(deep_replace(flatten_hash(settings)), true)
      self
    end

    def post_process
      if @post_process_callbacks
        @post_process_callbacks.each do |callback|
          callback.call(self)
        end
      end
    end

    def on_post_process(&block)
      @post_process_callbacks ||= []
      @post_process_callbacks << block
    end

    def validate_all
      # lets merge the transient_settings again to see if new setting were added.
      self.merge(@transient_settings)

      @settings.each do |name, setting|
        setting.validate_value
      end
    end

    def ==(other)
      return false unless other.kind_of?(::LogStash::Settings)
      self.to_hash == other.to_hash
    end

    private
    def read_yaml(path)
      YAML.safe_load(IO.read(path)) || {}
    end

    def flatten_hash(h, f = "", g = {})
      return g.update({ f => h }) unless h.is_a? Hash
      if f.empty?
        h.each { |k, r| flatten_hash(r, k, g) }
      else
        h.each { |k, r| flatten_hash(r, "#{f}.#{k}", g) }
      end
      g
    end
  end

  class Setting
    include LogStash::Settings::LOGGABLE_PROXY

    attr_reader :name, :default

    def initialize(name, klass, default = nil, strict = true, &validator_proc)
      @name = name
      unless klass.is_a?(Class)
        raise ArgumentError.new("Setting \"#{@name}\" must be initialized with a class (received #{klass})")
      end
      @klass = klass
      @validator_proc = validator_proc
      @value = nil
      @value_is_set = false
      @strict = strict

      validate(default) if @strict
      @default = default
    end

    def value
      @value_is_set ? @value : default
    end

    def set?
      @value_is_set
    end

    def strict?
      @strict
    end

    def set(value)
      validate(value) if @strict
      @value = value
      @value_is_set = true
      @value
    end

    def reset
      @value = nil
      @value_is_set = false
    end

    def to_hash
      {
        "name" => @name,
        "klass" => @klass,
        "value" => @value,
        "value_is_set" => @value_is_set,
        "default" => @default,
        # Proc#== will only return true if it's the same obj
        # so no there's no point in comparing it
        # also thereś no use case atm to return the proc
        # so let's not expose it
        #"validator_proc" => @validator_proc
      }
    end

    def inspect
      "<#{self.class.name}(#{name}): #{value.inspect}" + (@value_is_set ? '' : ' (DEFAULT)') + ">"
    end

    def ==(other)
      self.to_hash == other.to_hash
    end

    def validate_value
      validate(value)
    end

    def with_deprecated_alias(deprecated_alias_name)
      SettingWithDeprecatedAlias.wrap(self, deprecated_alias_name)
    end

    ##
    # Returns a Nullable-wrapped self, effectively making the Setting optional.
    def nullable
      Nullable.new(self)
    end

    def format(output)
      effective_value = self.value
      default_value = self.default
      setting_name = self.name

      if default_value == value # print setting and its default value
        output << "#{setting_name}: #{effective_value.inspect}" unless effective_value.nil?
      elsif default_value.nil? # print setting and warn it has been set
        output << "*#{setting_name}: #{effective_value.inspect}"
      elsif effective_value.nil? # default setting not set by user
        output << "#{setting_name}: #{default_value.inspect}"
      else # print setting, warn it has been set, and show default value
        output << "*#{setting_name}: #{effective_value.inspect} (default: #{default_value.inspect})"
      end
    end

    protected
    def validate(input)
      if !input.is_a?(@klass)
        raise ArgumentError.new("Setting \"#{@name}\" must be a #{@klass}. Received: #{input} (#{input.class})")
      end

      if @validator_proc && !@validator_proc.call(input)
        raise ArgumentError.new("Failed to validate setting \"#{@name}\" with value: #{input}")
      end
    end

    class Coercible < Setting
      def initialize(name, klass, default = nil, strict = true, &validator_proc)
        @name = name
        unless klass.is_a?(Class)
          raise ArgumentError.new("Setting \"#{@name}\" must be initialized with a class (received #{klass})")
        end
        @klass = klass
        @validator_proc = validator_proc
        @value = nil
        @value_is_set = false

        if strict
          coerced_default = coerce(default)
          validate(coerced_default)
          @default = coerced_default
        else
          @default = default
        end
      end

      def set(value)
        coerced_value = coerce(value)
        validate(coerced_value)
        @value = coerce(coerced_value)
        @value_is_set = true
        @value
      end

      def coerce(value)
        raise NotImplementedError.new("Please implement #coerce for #{self.class}")
      end
    end
    ### Specific settings #####

    class Boolean < Coercible
      def initialize(name, default, strict = true, &validator_proc)
        super(name, Object, default, strict, &validator_proc)
      end

      def coerce(value)
        case value
        when TrueClass, "true"
          true
        when FalseClass, "false"
          false
        else
          raise ArgumentError.new("could not coerce #{value} into a boolean")
        end
      end
    end

    class Numeric < Coercible
      def initialize(name, default = nil, strict = true)
        super(name, ::Numeric, default, strict)
      end

      def coerce(v)
        return v if v.is_a?(::Numeric)

        # I hate these "exceptions as control flow" idioms
        # but Ruby's `"a".to_i => 0` makes it hard to do anything else.
        coerced_value = (Integer(v) rescue nil) || (Float(v) rescue nil)

        if coerced_value.nil?
          raise ArgumentError.new("Failed to coerce value to Numeric. Received #{v} (#{v.class})")
        else
          coerced_value
        end
      end
    end

    class Integer < Coercible
      def initialize(name, default = nil, strict = true)
        super(name, ::Integer, default, strict)
      end

      def coerce(value)
        return value unless value.is_a?(::String)

        coerced_value = Integer(value) rescue nil

        if coerced_value.nil?
          raise ArgumentError.new("Failed to coerce value to Integer. Received #{value} (#{value.class})")
        else
          coerced_value
        end
      end
    end

    class PositiveInteger < Integer
      def initialize(name, default = nil, strict = true)
        super(name, default, strict) do |v|
          if v > 0
            true
          else
            raise ArgumentError.new("Number must be bigger than 0. Received: #{v}")
          end
        end
      end
    end

    class Port < Integer
      VALID_PORT_RANGE = 1..65535

      def initialize(name, default = nil, strict = true)
        super(name, default, strict) { |value| valid?(value) }
      end

      def valid?(port)
        VALID_PORT_RANGE.cover?(port)
      end
    end

    class PortRange < Coercible
      PORT_SEPARATOR = "-"

      def initialize(name, default = nil, strict = true)
        super(name, ::Range, default, strict = true) { |value| valid?(value) }
      end

      def valid?(range)
        Port::VALID_PORT_RANGE.first <= range.first && Port::VALID_PORT_RANGE.last >= range.last
      end

      def coerce(value)
        case value
        when ::Range
          value
        when ::Integer
          value..value
        when ::String
          first, last = value.split(PORT_SEPARATOR)
          last = first if last.nil?
          begin
            (Integer(first))..(Integer(last))
          rescue ArgumentError # Trap and reraise a more human error
            raise ArgumentError.new("Could not coerce #{value} into a port range")
          end
        else
          raise ArgumentError.new("Could not coerce #{value} into a port range")
        end
      end

      def validate(value)
        unless valid?(value)
          raise ArgumentError.new("Invalid value \"#{name}: #{value}\", valid options are within the range of #{Port::VALID_PORT_RANGE.first}-#{Port::VALID_PORT_RANGE.last}")
        end
      end
    end

    class Validator < Setting
      def initialize(name, default = nil, strict = true, validator_class = nil)
        @validator_class = validator_class
        super(name, ::Object, default, strict)
      end

      def validate(value)
        @validator_class.validate(value)
      end
    end

    class String < Setting
      def initialize(name, default = nil, strict = true, possible_strings = [])
        @possible_strings = possible_strings
        super(name, ::String, default, strict)
      end

      def validate(value)
        super(value)
        unless @possible_strings.empty? || @possible_strings.include?(value)
          raise ArgumentError.new("Invalid value \"#{name}: #{value}\". Options are: #{@possible_strings.inspect}")
        end
      end
    end

    class NullableString < String
      def validate(value)
        return if value.nil?
        super(value)
      end
    end

    class Password < Coercible
      def initialize(name, default = nil, strict = true)
        super(name, LogStash::Util::Password, default, strict)
      end

      def coerce(value)
        return value if value.kind_of?(LogStash::Util::Password)

        if value && !value.kind_of?(::String)
          raise(ArgumentError, "Setting `#{name}` could not coerce non-string value to password")
        end

        LogStash::Util::Password.new(value)
      end

      def validate(value)
        super(value)
      end
    end

    class ValidatedPassword < Setting::Password
      def initialize(name, value, password_policies)
        @password_policies = password_policies
        super(name, value, true)
      end

      def coerce(password)
        if password && !password.kind_of?(::LogStash::Util::Password)
          raise(ArgumentError, "Setting `#{name}` could not coerce LogStash::Util::Password value to password")
        end

        policies = build_password_policies
        validatedResult = LogStash::Util::PasswordValidator.new(policies).validate(password.value)
        if validatedResult.length() > 0
          if @password_policies.fetch(:mode).eql?("WARN")
            logger.warn("Password #{validatedResult}.")
          else
            raise(ArgumentError, "Password #{validatedResult}.")
          end
        end
        password
      end

      def build_password_policies
        policies = {}
        policies[Util::PasswordPolicyType::EMPTY_STRING] = Util::PasswordPolicyParam.new
        policies[Util::PasswordPolicyType::LENGTH] = Util::PasswordPolicyParam.new("MINIMUM_LENGTH", @password_policies.dig(:length, :minimum).to_s)
        if @password_policies.dig(:include, :upper).eql?("REQUIRED")
          policies[Util::PasswordPolicyType::UPPER_CASE] = Util::PasswordPolicyParam.new
        end
        if @password_policies.dig(:include, :lower).eql?("REQUIRED")
          policies[Util::PasswordPolicyType::LOWER_CASE] = Util::PasswordPolicyParam.new
        end
        if @password_policies.dig(:include, :digit).eql?("REQUIRED")
          policies[Util::PasswordPolicyType::DIGIT] = Util::PasswordPolicyParam.new
        end
        if @password_policies.dig(:include, :symbol).eql?("REQUIRED")
          policies[Util::PasswordPolicyType::SYMBOL] = Util::PasswordPolicyParam.new
        end
        policies
      end
    end

    # The CoercibleString allows user to enter any value which coerces to a String.
    # For example for true/false booleans; if the possible_strings are ["foo", "true", "false"]
    # then these options in the config file or command line will be all valid: "foo", true, false, "true", "false"
    #
    class CoercibleString < Coercible
      def initialize(name, default = nil, strict = true, possible_strings = [], &validator_proc)
        @possible_strings = possible_strings
        super(name, Object, default, strict, &validator_proc)
      end

      def coerce(value)
        value.to_s
      end

      def validate(value)
        super(value)
        unless @possible_strings.empty? || @possible_strings.include?(value)
          raise ArgumentError.new("Invalid value \"#{value}\". Options are: #{@possible_strings.inspect}")
        end
      end
    end

    class ExistingFilePath < Setting
      def initialize(name, default = nil, strict = true)
        super(name, ::String, default, strict) do |file_path|
          if !::File.exist?(file_path)
            raise ::ArgumentError.new("File \"#{file_path}\" must exist but was not found.")
          else
            true
          end
        end
      end
    end

    class WritableDirectory < Setting
      def initialize(name, default = nil, strict = false)
        super(name, ::String, default, strict)
      end

      def validate(path)
        super(path)

        if ::File.directory?(path)
          if !::File.writable?(path)
            raise ::ArgumentError.new("Path \"#{path}\" must be a writable directory. It is not writable.")
          end
        elsif ::File.symlink?(path)
          # TODO(sissel): I'm OK if we relax this restriction. My experience
          # is that it's usually easier and safer to just reject symlinks.
          raise ::ArgumentError.new("Path \"#{path}\" must be a writable directory. It cannot be a symlink.")
        elsif ::File.exist?(path)
          raise ::ArgumentError.new("Path \"#{path}\" must be a writable directory. It is not a directory.")
        else
          parent = ::File.dirname(path)
          if !::File.writable?(parent)
            raise ::ArgumentError.new("Path \"#{path}\" does not exist and I cannot create it because the parent path \"#{parent}\" is not writable.")
          end
        end

        # If we get here, the directory exists and is writable.
        true
      end

      def value
        super.tap do |path|
          if !::File.directory?(path)
            # Create the directory if it doesn't exist.
            begin
              logger.info("Creating directory", setting: name, path: path)
              ::FileUtils.mkdir_p(path)
            rescue => e
              # TODO(sissel): Catch only specific exceptions?
              raise ::ArgumentError.new("Path \"#{path}\" does not exist, and I failed trying to create it: #{e.class.name} - #{e}")
            end
          end
        end
      end
    end

    class Bytes < Coercible
      def initialize(name, default = nil, strict = true)
        super(name, ::Integer, default, strict = true) { |value| valid?(value) }
      end

      def valid?(value)
        value.is_a?(::Integer) && value >= 0
      end

      def coerce(value)
        case value
        when ::Numeric
          value
        when ::String
          LogStash::Util::ByteValue.parse(value)
        else
          raise ArgumentError.new("Could not coerce '#{value}' into a bytes value")
        end
      end

      def validate(value)
        unless valid?(value)
          raise ArgumentError.new("Invalid byte value \"#{value}\".")
        end
      end
    end

    class TimeValue < Coercible
      include LogStash::Util::Loggable

      def initialize(name, default, strict = true, &validator_proc)
        super(name, Util::TimeValue, default, strict, &validator_proc)
      end

      def coerce(value)
        if value.is_a?(::Integer)
          deprecation_logger.deprecated("Integer value for `#{name}` does not have a time unit and will be interpreted in nanoseconds. " +
                                        "Time units will be required in a future release of Logstash. " +
                                        "Acceptable unit suffixes are: `d`, `h`, `m`, `s`, `ms`, `micros`, and `nanos`.")

          return Util::TimeValue.new(value, :nanosecond)
        end

        Util::TimeValue.from_value(value)
      end
    end

    class ArrayCoercible < Coercible
      def initialize(name, klass, default, strict = true, &validator_proc)
        @element_class = klass
        super(name, ::Array, default, strict, &validator_proc)
      end

      def coerce(value)
        Array(value)
      end

      protected
      def validate(input)
        if !input.is_a?(@klass)
          raise ArgumentError.new("Setting \"#{@name}\" must be a #{@klass}. Received: #{input} (#{input.class})")
        end

        unless input.all? {|el| el.kind_of?(@element_class) }
          raise ArgumentError.new("Values of setting \"#{@name}\" must be #{@element_class}. Received: #{input.map(&:class)}")
        end

        if @validator_proc && !@validator_proc.call(input)
          raise ArgumentError.new("Failed to validate setting \"#{@name}\" with value: #{input}")
        end
      end
    end

    class SplittableStringArray < ArrayCoercible
      DEFAULT_TOKEN = ","

      def initialize(name, klass, default, strict = true, tokenizer = DEFAULT_TOKEN, &validator_proc)
        @element_class = klass
        @token = tokenizer
        super(name, klass, default, strict, &validator_proc)
      end

      def coerce(value)
        if value.is_a?(Array)
          value
        elsif value.nil?
          []
        else
          value.split(@token).map(&:strip)
        end
      end
    end

    class StringArray < ArrayCoercible
      def initialize(name, default, strict = true, possible_strings = [], &validator_proc)
        @possible_strings = possible_strings
        super(name, ::String, default, strict, &validator_proc)
      end

      protected

      def validate(value)
        super(value)
        return unless @possible_strings&.any?

        invalid_value = coerce(value).reject { |val| @possible_strings.include?(val) }
        return unless invalid_value.any?

        raise ArgumentError,
          "Failed to validate the setting \"#{@name}\" value(s): #{invalid_value.inspect}. Valid options are: #{@possible_strings.inspect}"
      end
    end

    class Modules < Coercible
      def initialize(name, klass, default = nil)
        super(name, klass, default, false)
      end

      def set(value)
        @value = coerce(value)
        @value_is_set = true
        @value
      end

      def coerce(value)
        if value.is_a?(@klass)
          return value
        end
        @klass.new(value)
      end

      protected
      def validate(value)
        coerce(value)
      end
    end

    # @see Setting#nullable
    # @api internal
    class Nullable < SimpleDelegator
      def validate(value)
        return true if value.nil?

        __getobj__.send(:validate, value)
      end

      # prevent delegate from intercepting
      def validate_value
        validate(value)
      end
    end

    ##
    # @api private
    #
    # A DeprecatedAlias provides a deprecated alias for a setting, and is meant
    # to be used exclusively through `SettingWithDeprecatedAlias#wrap`
    class DeprecatedAlias < SimpleDelegator
      # include LogStash::Util::Loggable
      alias_method :wrapped, :__getobj__
      attr_reader :canonical_proxy

      def initialize(canonical_proxy, alias_name)
        @canonical_proxy = canonical_proxy

        clone = @canonical_proxy.canonical_setting.clone
        clone.instance_variable_set(:@name, alias_name)
        clone.instance_variable_set(:@default, nil)

        super(clone)
      end

      def set(value)
        deprecation_logger.deprecated(I18n.t("logstash.settings.deprecation.set",
                                             :deprecated_alias => name,
                                             :canonical_name => canonical_proxy.name))
        super
      end

      def value
        logger.warn(I18n.t("logstash.settings.deprecation.queried",
                           :deprecated_alias => name,
                           :canonical_name => canonical_proxy.name))
        @canonical_proxy.value
      end

      def validate_value
        # bypass deprecation warning
        wrapped.validate_value if set?
      end
    end

    ##
    # A SettingWithDeprecatedAlias wraps any Setting to provide a deprecated
    # alias, and hooks `Setting#validate_value` to ensure that a deprecation
    # warning is fired when the setting is provided by its deprecated alias,
    # or to produce an error when both the canonical name and deprecated
    # alias are used together.
    class SettingWithDeprecatedAlias < SimpleDelegator

      ##
      # Wraps the provided setting, returning a pair of connected settings
      # including the canonical setting and a deprecated alias.
      # @param canonical_setting [Setting]: the setting to wrap
      # @param deprecated_alias_name [String]: the name for the deprecated alias
      #
      # @return [SettingWithDeprecatedAlias,DeprecatedSetting]
      def self.wrap(canonical_setting, deprecated_alias_name)
        setting_proxy = new(canonical_setting, deprecated_alias_name)

        [setting_proxy, setting_proxy.deprecated_alias]
      end

      attr_reader :deprecated_alias
      alias_method :canonical_setting, :__getobj__

      def initialize(canonical_setting, deprecated_alias_name)
        super(canonical_setting)

        @deprecated_alias = DeprecatedAlias.new(self, deprecated_alias_name)
      end

      def set(value)
        canonical_setting.set(value)
      end

      def value
        return super if canonical_setting.set?

        # bypass warning by querying the wrapped setting's value
        return deprecated_alias.wrapped.value if deprecated_alias.set?

        default
      end

      def set?
        canonical_setting.set? || deprecated_alias.set?
      end

      def format(output)
        return super unless deprecated_alias.set? && !canonical_setting.set?

        output << "*#{self.name}: #{value.inspect} (via deprecated `#{deprecated_alias.name}`; default: #{default.inspect})"
      end

      def validate_value
        if deprecated_alias.set? && canonical_setting.set?
          fail(ArgumentError, I18n.t("logstash.settings.deprecation.ambiguous",
                                     :canonical_name => canonical_setting.name,
                                     :deprecated_alias => deprecated_alias.name))
        end

        super
      end
    end
  end

  SETTINGS = Settings.new
end
