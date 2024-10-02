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

java_import "org.logstash.secret.store.SecretStoreExt"

require_relative 'lazy_singleton'
require_relative 'password'

module ::LogStash::Util::SubstitutionVariables
  include LogStash::Util::Loggable

  SUBSTITUTION_PLACEHOLDER_REGEX = /\${(?<name>[a-zA-Z_.][a-zA-Z0-9_.]*)(:(?<default>[^}]*))?}/

  SECRET_STORE = ::LogStash::Util::LazySingleton.new { load_secret_store }
  private_constant :SECRET_STORE

  # Recursive method to replace substitution variable references in parameters and refine if required
  def deep_replace(value, refine = false)
    if value.is_a?(Hash)
      value.each do |valueHashKey, valueHashValue|
        value[valueHashKey.to_s] = deep_replace(valueHashValue, refine)
      end
    else
      if value.is_a?(Array)
        value.each_with_index do |single_value, i|
          value[i] = deep_replace(single_value, refine)
        end
      else
        return replace_placeholders(value, refine)
      end
    end
  end

  # Replace all substitution variable references in the 'value' param and returns the substituted value, or the original value if a substitution can not be made
  # Process following patterns : ${VAR}, ${VAR:defaultValue}
  # If value matches the pattern, returns the following precedence : Secret store value, Environment entry value, default value as provided in the pattern
  # If the value does not match the pattern, the 'value' param returns as-is
  # When setting refine to true, substituted value will be cleaned against escaped single/double quotes
  #   and generates array if resolved substituted value is array string
  def replace_placeholders(value, refine = false)
    if value.kind_of?(::LogStash::Util::Password)
      interpolated = replace_placeholders(value.value, refine)
      return ::LogStash::Util::Password.new(interpolated)
    end
    return value unless value.is_a?(String)

    is_placeholder_found = false
    placeholder_value = value.gsub(SUBSTITUTION_PLACEHOLDER_REGEX) do |placeholder|
      # Note: Ruby docs claim[1] Regexp.last_match is thread-local and scoped to
      # the call, so this should be thread-safe.
      #
      # [1] http://ruby-doc.org/core-2.1.1/Regexp.html#method-c-last_match
      name = Regexp.last_match(:name)
      default = Regexp.last_match(:default)
      logger.debug("Replacing `#{placeholder}` with actual value")

      is_placeholder_found = true

      #check the secret store if it exists
      secret_store = SECRET_STORE.instance
      replacement = secret_store.nil? ? nil : secret_store.retrieveSecret(SecretStoreExt.getStoreId(name))
      #check the environment
      replacement = ENV.fetch(name, default) if replacement.nil?
      if replacement.nil?
        raise LogStash::ConfigurationError, "Cannot evaluate `#{placeholder}`. Replacement variable `#{name}` is not defined in a Logstash secret store " +
            "or as an Environment entry and there is no default value given."
      end
      replacement.to_s
    end

    # no further action need if substitution didn't happen or refine isn't required
    return placeholder_value unless is_placeholder_found && refine

    # ENV ${var} value may carry single quote or escaped double quote
    # or single/double quoted entries in array string, needs to be refined
    refined_value = strip_enclosing_char(strip_enclosing_char(placeholder_value, "'"), '"')
    if refined_value.start_with?('[') && refined_value.end_with?(']')
      # remove square brackets, split by comma and cleanup leading/trailing whitespace
      refined_array = refined_value[1..-2].split(',').map(&:strip)
      refined_array.each_with_index do |str, index|
        refined_array[index] = strip_enclosing_char(strip_enclosing_char(str, "'"), '"')
      end
      refined_array
    else
      refined_value
    end
  end # def replace_placeholders

  private

  # removes removed_char of string_value if string_value is wrapped with removed_char
  def strip_enclosing_char(string_value, remove_char)
    return string_value unless string_value.is_a?(String)
    return string_value if string_value.empty?

    if string_value.start_with?(remove_char) && string_value.end_with?(remove_char)
      string_value[1..-2] # Remove the first and last characters
    else
      string_value
    end
  end

  class << self
    private

    # loads a secret_store from disk if available, or returns nil
    #
    # @api private
    # @return [SecretStoreExt,nil]
    def load_secret_store
      SecretStoreExt.getIfExists(LogStash::SETTINGS.get_setting("keystore.file").value, LogStash::SETTINGS.get_setting("keystore.classname").value)
    end

    # @api test
    def reset_secret_store
      SECRET_STORE.reset!
    end
  end
end
