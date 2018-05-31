package org.logstash.common;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.SecretStore;
import org.logstash.secret.store.SecretStoreException;
import org.logstash.secret.store.SecretStoreFactory;
import org.logstash.secret.store.SecureConfig;

import java.util.Map;
import java.util.function.Function;
import java.util.regex.Pattern;

public class SubstitutionVariables {
    private static final Logger logger = LogManager.getLogger(SubstitutionVariables.class);

    private static Pattern SUBSTITUTION_PLACEHOLDER_REGEX = Pattern.compile("\\$\\{(?<name>[a-zA-Z_.][a-zA-Z0-9_.]*)(:(?<default>[^}]*))?\\}");

    private static final SecretStoreFactory secretStoreFactory = SecretStoreFactory.fromEnvironment();

    static String replacePlaceholders(final String input,
                                      final Map<String, String> environmentVariables,
                                      SecureConfig secureConfig) {
        return replacePlaceholders(input, environmentVariables, (name) -> {
            // TODO: This is an expensive operation, often 300ms if the SS exists, so we only do it on
            // match results. In the future we should cache secret stores based on contents of the SS.
            SecretStore secretStore = null;
            try {
                if (secretStoreFactory.exists(secureConfig)) {
                    secretStoreFactory.load(secureConfig);
                }
            } catch (SecretStoreException.AccessException e) {
                // Non-fatal condition
                logger.warn("Could not load secret store ", e);
            }

            if (secretStore != null) {
                    byte[] secretValue = secretStore.retrieveSecret(new SecretIdentifier(name));
                    if (secretValue != null) return new String(secretValue);
            }

            return null;
        });
    }

    static String replacePlaceholders(final String input,
                                      final Map<String, String> environmentVariables,
                                      final Function<String, String> secretLookup) {

        return Util.gsub(input, SUBSTITUTION_PLACEHOLDER_REGEX, (matchResult) -> {
            String name = matchResult.group(1);
            String defaultValue = matchResult.group(3);

            final String secureValue = secretLookup != null ? secretLookup.apply(name) : null;
            if (secureValue != null) return secureValue;

            final String envValue = environmentVariables.getOrDefault(name, defaultValue);
            if (envValue != null) return envValue;

            String errMsg = String.format(
                    "Cannot evaluate `%s`. Replacement variable `%s` is not defined in a Logstash secret store " +
                            "or as an Environment entry and there is no default value given.",
                    matchResult.group(0), name);
            throw new MissingSubstitutionVariableError();
        });
    }

    static class MissingSubstitutionVariableError extends RuntimeException {}
}
