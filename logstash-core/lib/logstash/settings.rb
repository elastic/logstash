# encoding: utf-8

module LogStash
  class Settings

    def initialize
      @settings = {}
    end

    def register(setting)
      if @settings.key?(setting.name)
        raise ArgumentError.new("Setting \"#{setting.name}\" has already been registered as #{setting.inspect}")
      else
        @settings[setting.name] = setting
      end
    end

    def get_setting(setting_name)
      setting = @settings[setting_name]
      raise ArgumentError.new("Setting \"#{setting_name}\" hasn't been registered") if setting.nil?
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

    def set?(setting_name)
      get_setting(setting_name).set?
    end

    def clone
      get_subset(".*")
    end

    def get_default(setting_name)
      get_setting(setting_name).default
    end

    def get_value(setting_name)
      get_setting(setting_name).value
    end
    alias_method :get, :get_value

    def set_value(setting_name, value)
      get_setting(setting_name).set(value)
    end
    alias_method :set, :set_value

    def to_hash
      hash = {}
      @settings.each do |name, setting|
        hash[name] = setting.value
      end
      hash
    end

    def merge(hash)
      hash.each {|key, value| set_value(key, value) }
      self
    end

    def format_settings
      output = []
      output << "-------- Logstash Settings (* means modified) ---------"
      @settings.each do |setting_name, setting|
        value = setting.value
        default_value = setting.default
        if default_value == value # print setting and its default value
          output << "#{setting_name}: #{value.inspect}" unless value.nil?
        elsif default_value.nil? # print setting and warn it has been set
          output << "*#{setting_name}: #{value.inspect}"
        elsif value.nil? # default setting not set by user
          output << "#{setting_name}: #{default_value.inspect}"
        else # print setting, warn it has been set, and show default value
          output << "*#{setting_name}: #{value.inspect} (default: #{default_value.inspect})"
        end
      end
      output << "--------------- Logstash Settings -------------------"
      output
    end

    def reset
      @settings.values.each(&:reset)
    end

    def from_yaml(yaml_path)
      settings = read_yaml(::File.join(yaml_path, "logstash.yml"))
      self.merge(flatten_hash(settings))
    end

    private
    def read_yaml(path)
      YAML.safe_load(IO.read(path)) || {}
    end

    def flatten_hash(h,f="",g={})
      return g.update({ f => h }) unless h.is_a? Hash
      if f.empty?
        h.each { |k,r| flatten_hash(r,k,g) }
      else
        h.each { |k,r| flatten_hash(r,"#{f}.#{k}",g) }
      end
      g
    end
  end

  class Setting
    attr_reader :name, :default

    def initialize(name, klass, default=nil, strict=true, &validator_proc)
      @name = name
      unless klass.is_a?(Class)
        raise ArgumentError.new("Setting \"#{@name}\" must be initialized with a class (received #{klass})")
      end
      @klass = klass
      @validator_proc = validator_proc
      @value = nil
      @value_is_set = false

      validate(default) if strict
      @default = default
    end

    def value
      @value_is_set ? @value : default
    end

    def set?
      @value_is_set
    end

    def set(value)
      validate(value)
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

    def ==(other)
      self.to_hash == other.to_hash
    end

    private
    def validate(value)
      if !value.is_a?(@klass)
        raise ArgumentError.new("Setting \"#{@name}\" must be a #{@klass}. Received: #{value} (#{value.class})")
      elsif @validator_proc && !@validator_proc.call(value)
        raise ArgumentError.new("Failed to validate setting \"#{@name}\" with value: #{value}")
      end
    end

    ### Specific settings #####

    class Boolean < Setting
      def initialize(name, default, strict=true, &validator_proc)
        @name = name
        @klass = Object
        @value = nil
        @value_is_set = false
        @validator_proc = validator_proc
        coerced_default = coerce(default)
        validate(coerced_default)
        @default = coerced_default
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

      def set(value)
        coerced_value = coerce(value)
        validate(coerced_value)
        @value = coerce(coerced_value)
        @value_is_set = true
        @value
      end
    end

    class Numeric < Setting
      def initialize(name, default=nil, strict=true)
        super(name, ::Numeric, default, strict)
      end
    end

    class Port < Setting
      def initialize(name, default=nil, strict=true)
        super(name, ::Numeric, default, strict) {|value| value >= 1 && value <= 65535 }
      end
    end

    class Validator < Setting
      def initialize(name, default=nil, strict=true, validator_class=nil)
        @validator_class = validator_class
        super(name, ::Object, default, strict)
      end

      def validate(value)
        @validator_class.validate(value)
      end
    end

    class String < Setting
      def initialize(name, default=nil, strict=true, possible_strings=[])
        @possible_strings = possible_strings
        super(name, ::String, default, strict)
      end

      def validate(value)
        super(value)
        unless @possible_strings.empty? || @possible_strings.include?(value)
          raise ArgumentError.new("invalid value \"#{value}\". Options are: #{@possible_strings.inspect}")
        end
      end
    end

    class ExistingFilePath < Setting
      def initialize(name, default=nil, strict=true)
        super(name, ::String, default, strict) do |file_path|
          if !::File.exists?(file_path)
            raise ::ArgumentError.new("File \"#{file_path}\" must exist but was not found.")
          else
            true
          end
        end
      end
    end

    class WritableDirectory < Setting
      def initialize(name, default=nil, strict=true)
        super(name, ::String, default, strict) do |path|
          if ::File.directory?(path) && ::File.writable?(path)
            true
          else
            raise ::ArgumentError.new("Path \"#{path}\" is not a directory or not writable.")
          end
        end
      end
    end

  end

  SETTINGS = Settings.new
end
