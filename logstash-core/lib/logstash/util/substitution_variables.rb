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

  # Recursive method to replace substitution variable references in parameters
  def deep_replace(value, substitute_with_secret_store = true)
    if value.is_a?(Hash)
      value.each do |valueHashKey, valueHashValue|
        value[valueHashKey.to_s] = deep_replace(valueHashValue, substitute_with_secret_store)
      end
    else
      if value.is_a?(Array)
        value.each_index do | valueArrayIndex|
          value[valueArrayIndex] = deep_replace(value[valueArrayIndex], substitute_with_secret_store)
        end
      else
        return replace_placeholders(value, substitute_with_secret_store)
      end
    end
  end

  # Replace all substitution variable references, ${VAR}, ${VAR:defaultValue}, in the 'value' param and
  # returns the substituted value as following precedence : Secret store value, Environment entry value, default value as provided in the pattern
  # When substitute_with_secret_store flog is false, it does not take the substitution from secret store.
  #   If no substitution found, return the original pattern

  def replace_placeholders(value, substitute_with_secret_store = true)
    if value.kind_of?(::LogStash::Util::Password)
      interpolated = replace_placeholders(value.value, substitute_with_secret_store)
      return ::LogStash::Util::Password.new(interpolated)
    end
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
      secret_store = SECRET_STORE.instance
      replacement = secret_store.nil? ? nil : secret_store.retrieveSecret(SecretStoreExt.getStoreId(name))

      #check the environment
      replacement = ENV.fetch(name, default) if replacement.nil?
      if replacement.nil?
        raise LogStash::ConfigurationError, "Cannot evaluate `#{placeholder}`. Replacement variable `#{name}` is not defined in a Logstash secret store " +
            "or as an Environment entry and there is no default value given."
      end

      if substitute_with_secret_store
        replacement
      else
        ENV.fetch(name, default) || placeholder
      end
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
