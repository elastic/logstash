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

    public ConfigVariableExpander(SecretStore secretStore, EnvironmentVariableProvider envVarProvider) {
        this.secretStore = secretStore;
        this.envVarProvider = envVarProvider;
    }

    /**
     * Replace all substitution variable references in @variable and returns the substituted value, or the
     * original value if a substitution cannot be made.
     *
     * Process following patterns : ${VAR}, ${VAR:defaultValue}
     *
     * If value matches the pattern, the following precedence applies:
     *   Secret store value
     *   Environment entry value
     *   Default value if provided in the pattern
     *   Exception raised
     *
     * If the value does not match the pattern, the 'value' param returns as-is
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
