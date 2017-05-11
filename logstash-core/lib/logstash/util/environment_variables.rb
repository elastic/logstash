# encoding: utf-8
module ::LogStash::Util::EnvironmentVariables

  ENV_PLACEHOLDER_REGEX = /\${(?<name>[a-zA-Z_.][a-zA-Z0-9_.]*)(:(?<default>[^}]*))?}/

  # Recursive method to replace environment variable references in parameters
  def deep_replace(value)
    if value.is_a?(Hash)
      value.each do |valueHashKey, valueHashValue|
        value[valueHashKey.to_s] = deep_replace(valueHashValue)
      end
    else
      if value.is_a?(Array)
        value.each_index do | valueArrayIndex|
          value[valueArrayIndex] = deep_replace(value[valueArrayIndex])
        end
      else
        return replace_env_placeholders(value)
      end
    end
  end

  # Replace all environment variable references in 'value' param by environment variable value and return updated value
  # Process following patterns : $VAR, ${VAR}, ${VAR:defaultValue}
  def replace_env_placeholders(value)
    return value unless value.is_a?(String)

    value.gsub(ENV_PLACEHOLDER_REGEX) do |placeholder|
      # Note: Ruby docs claim[1] Regexp.last_match is thread-local and scoped to
      # the call, so this should be thread-safe.
      #
      # [1] http://ruby-doc.org/core-2.1.1/Regexp.html#method-c-last_match
      name = Regexp.last_match(:name)
      default = Regexp.last_match(:default)

      replacement = ENV.fetch(name, default)
      if replacement.nil?
        raise LogStash::ConfigurationError, "Cannot evaluate `#{placeholder}`. Environment variable `#{name}` is not set and there is no default value given."
      end
      replacement
    end
  end # def replace_env_placeholders
end
