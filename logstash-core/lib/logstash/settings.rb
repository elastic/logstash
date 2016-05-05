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
      @value_is_set = true unless @value_is_set
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
  end

  class BooleanSetting < Setting
    def initialize(name, default=nil, strict=true)
      # Ruby doesn't have a single class to represent booleans
      # so let's use the proc validator instead
      super(name, Object, default, strict) {|value| [true, false].include?(value) }
    end
  end

  class ValidatorSetting < Setting
    def initialize(name, default=nil, strict=true, validator_class=nil)
      @validator_class = validator_class
      # Ruby doesn't have a single class to represent booleans
      # so let's use the proc validator instead
      super(name, Object, default, strict)
    end

    def validate(value)
      @validator_class.validate(value)
    end
  end

  class ExistingFilePathSetting < Setting
    def initialize(name, default=nil, strict=true)
      super(name, String, default, strict) do |file_path|
        if !::File.exists?(file_path)
          raise ArgumentError.new("File \"#{file_path}\" must exist but was not found.")
        else
          true
        end
      end
    end
  end

  SETTINGS = Settings.new
end
