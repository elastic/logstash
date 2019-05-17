# encoding: utf-8

java_import "org.logstash.secret.store.SecretStoreExt"

module ::LogStash::Util::SubstitutionVariables

  include LogStash::Util::Loggable

  SUBSTITUTION_PLACEHOLDER_REGEX = /\${(?<name>[a-zA-Z_.][a-zA-Z0-9_.]*)(:(?<default>[^}]*))?}/

  # Recursive method to replace substitution variable references in parameters
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
        return replace_placeholders(value)
      end
    end
  end

  # Replace all substitution variable references in the 'value' param and returns the substituted value, or the original value if a substitution can not be made
  # Process following patterns : ${VAR}, ${VAR:defaultValue}
  # If value matches the pattern, returns the following precedence : Secret store value, Environment entry value, default value as provided in the pattern
  # If the value does not match the pattern, the 'value' param returns as-is
  def replace_placeholders(value)
    return value unless value.is_a?(String)

    value.gsub(SUBSTITUTION_PLACEHOLDER_REGEX) do |placeholder|
      # Note: Ruby docs claim[1] Regexp.last_match is thread-local and scoped to
      # the call, so this should be thread-safe.
      #
      # [1] http://ruby-doc.org/core-2.1.1/Regexp.html#method-c-last_match
      name = Regexp.last_match(:name)
      default = Regexp.last_match(:default)
      logger.debug("Replacing `#{placeholder}` with actual value")

      #check the secret store if it exists
      secret_store = get_or_load_secret_store
      replacement = secret_store.nil? ? nil : secret_store.retrieveSecret(SecretStoreExt.getStoreId(name))
      #check the environment
      replacement = ENV.fetch(name, default) if replacement.nil?
      if replacement.nil?
        raise LogStash::ConfigurationError, "Cannot evaluate `#{placeholder}`. Replacement variable `#{name}` is not defined in a Logstash secret store " +
            "or as an Environment entry and there is no default value given."
      end
      replacement.to_s
    end
  end # def replace_placeholders

  # helper method to cache a single secret_store for the current thread
  # across all calls within the provided block, cleaning up when finished
  #
  # @yield control
  def with_exclusive_secret_store
    subsitution_variable_mutex.synchronize do
      begin
        logger.info("Setting up exclusive keystore for #{self.inspect}...")
        @_secret_store = load_secret_store
        yield
      ensure
        @_secret_store = nil
        logger.info("Revoking exclusive keystore for #{self.inspect}...")
      end
    end
  end

  private

  # get a secret_store, using a cached value if available.
  # @api private
  # @return [SecretStoreExt,nil]
  def get_or_load_secret_store
    return @_secret_store if subsitution_variable_mutex.owned?

    load_secret_store
  end

  # loads a secret_store from disk if available
  # @api private
  # # @return [SecretStoreExt,nil]
  def load_secret_store
    SecretStoreExt.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value)
  end

  # returns an instance-specific mutex, for use
  # @api private
  def subsitution_variable_mutex
    # to ensure that the instance that this module is mixed into
    # gets EXACTLY ONE mutex, we briefly use a global mutex.
    @_subsitution_variable_mutex || MUTEX.synchronize do
      @_subsitution_variable_mutex ||= Mutex.new
    end
  end

  MUTEX = Mutex.new
  private_constant :MUTEX
end
