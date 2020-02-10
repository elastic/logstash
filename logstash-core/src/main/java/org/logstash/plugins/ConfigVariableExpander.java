package org.logstash.plugins;

import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.SecretStore;

import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class ConfigVariableExpander implements AutoCloseable {

    private static String SUBSTITUTION_PLACEHOLDER_REGEX = "\\$\\{(?<name>[a-zA-Z_.][a-zA-Z0-9_.]*)(:(?<default>[^}]*))?}";

    private Pattern substitutionPattern = Pattern.compile(SUBSTITUTION_PLACEHOLDER_REGEX);
    private SecretStore secretStore;
    private EnvironmentVariableProvider envVarProvider;

    /**
     * Creates a ConfigVariableExpander that doesn't lookup any secreted placeholder.
     * */
    static ConfigVariableExpander withoutSecret(EnvironmentVariableProvider envVarProvider) {
        return new ConfigVariableExpander(null, envVarProvider);
    }

    public ConfigVariableExpander(SecretStore secretStore, EnvironmentVariableProvider envVarProvider) {
        this.secretStore = secretStore;
        this.envVarProvider = envVarProvider;
    }

    /**
     * Replace all substitution variable references and returns the substituted value or the original value
     * if a substitution cannot be made.
     *
     * Substitution variables have the patterns: <code>${VAR}</code> or <code>${VAR:defaultValue}</code>
     *
     * If a substitution variable is found, the following precedence applies:
     *   Secret store value
     *   Environment entry value
     *   Default value if provided in the pattern
     *   Exception raised
     *
     * If a substitution variable is not found, the value is return unchanged
     *
     * @param value Config value in which substitution variables, if any, should be replaced.
     * @return Config value with any substitution variables replaced
     */
    public Object expand(Object value) {
        String variable;
        if (value instanceof String) {
            variable = (String) value;
        } else {
            return value;
        }

        Matcher m = substitutionPattern.matcher(variable);
        if (m.matches()) {
            String variableName = m.group("name");

            if (secretStore != null) {
                byte[] ssValue = secretStore.retrieveSecret(new SecretIdentifier(variableName));
                if (ssValue != null) {
                    return new String(ssValue, StandardCharsets.UTF_8);
                }
            }

            if (envVarProvider != null) {
                String evValue = envVarProvider.get(variableName);
                if (evValue != null) {
                    return evValue;
                }
            }

            String defaultValue = m.group("default");
            if (defaultValue != null) {
                return defaultValue;
            }

            throw new IllegalStateException(String.format(
                    "Cannot evaluate `%s`. Replacement variable `%s` is not defined in a Logstash " +
                            "secret store or an environment entry and there is no default value given.",
                    variable, variableName));
        } else {
            return variable;
        }
    }

    @Override
    public void close() {
        // most keystore implementations will have close() methods

    }
}
