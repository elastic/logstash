/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.secret.store;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.SecretIdentifier;

import java.lang.reflect.InvocationTargetException;
import java.util.Map;

/**
 * <p>A factory to load the implementation of a {@link SecretStore}. Implementation may be defined via the {@link SecureConfig} via with a key of "keystore.classname" and
 * value equal to the fqn of the class that implements {@link SecretStore}
 * </p>
 */
public class SecretStoreFactory {
    @FunctionalInterface
    public interface EnvironmentVariableProvider {
        String get(String env);
    }

    private final EnvironmentVariableProvider environmentVariableProvider;

    public static final String KEYSTORE_ACCESS_KEY = "keystore.pass";
    //secret stores should create a secret with this as the key and value to identify a logstash secret
    public final static SecretIdentifier LOGSTASH_MARKER = new SecretIdentifier("keystore.seed");

    public final static String ENVIRONMENT_PASS_KEY = "LOGSTASH_KEYSTORE_PASS";

    /**
     * @return a {@link SecretStoreFactory} that is capable of pulling credentials from the process' environment
     *         variables using the platform-specific {@link System#getenv(String)}.
     */
    public static SecretStoreFactory fromEnvironment() {
        return new SecretStoreFactory(System::getenv);
    }

    /**
     * Get a {@link SecretStoreFactory} that is capable of pulling credentials from the specified environment variable map.
     *
     * Useful for testing scenarios, where overwriting the pseudo-immutable mapping of environment variables available
     * via official APIs would require platform-dependent hackery.
     *
     * @param environmentVariables a Map of environment variables that wholly-overrides the process' environment for
     *                             purposes of credential extraction by the returned instance of {@link SecretStoreFactory}.
     * @return a {@link SecretStoreFactory} that uses only the provided environment variables.
     */
    public static SecretStoreFactory withEnvironment(final Map<String,String> environmentVariables) {
        return new SecretStoreFactory(environmentVariables::get);
    }

    private SecretStoreFactory(final EnvironmentVariableProvider environmentVariableProvider) {
        this.environmentVariableProvider = environmentVariableProvider;
    }

    private static final Logger LOGGER = LogManager.getLogger(SecretStoreFactory.class);

    private enum MODE {LOAD, CREATE, EXISTS, DELETE}

    /**
     * Determine if this secret store currently exists
     * @param secureConfig The configuration to pass to the implementation
     * @return true if the secret store exists, false otherwise
     */
    public boolean exists(SecureConfig secureConfig) {
        return doIt(MODE.EXISTS, secureConfig).exists(secureConfig);
    }

    /**
     * Creates a new {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * @return the newly created SecretStore, throws {@link SecretStoreException} if errors occur while loading, or if store already exists
     */
    public SecretStore create(SecureConfig secureConfig) {
        return doIt(MODE.CREATE, secureConfig);
    }

    /**
     * Deletes a {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * throws {@link SecretStoreException} if errors occur
     */
    public void delete(SecureConfig secureConfig) {
        doIt(MODE.DELETE, secureConfig);
    }

    /**
     * Loads an existing {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * @return the loaded SecretStore, throws {@link SecretStoreException} if errors occur while loading, or if store does not exist
     */
    public SecretStore load(SecureConfig secureConfig) {
        return doIt(MODE.LOAD, secureConfig);
    }

    @SuppressWarnings({"unchecked", "JavaReflectionMemberAccess"})
    private SecretStore doIt(MODE mode, SecureConfig secureConfig) {
        char[] configuredClassName = secureConfig.getPlainText("keystore.classname");
        String className = configuredClassName != null ? new String(configuredClassName) : "org.logstash.secret.store.backend.JavaKeyStore";
        try {
            LOGGER.debug("Attempting to {} or secret store with implementation: {}", mode.name().toLowerCase(), className);
            Class<? extends SecretStore> implementation = (Class<? extends SecretStore>) Class.forName(className);

            addSecretStoreAccess(secureConfig);

            if (MODE.LOAD.equals(mode)) {
                return implementation.getConstructor().newInstance().load(secureConfig);
            } else if (MODE.CREATE.equals(mode)) {
                return implementation.getConstructor().newInstance().create(secureConfig);
            } else if (MODE.DELETE.equals(mode)) {
                implementation.getConstructor().newInstance().delete(secureConfig);
                return null;
            } else if (MODE.EXISTS.equals(mode)) {
                return implementation.getConstructor().newInstance();
            } else {
                throw new IllegalStateException("missing mode. This is bug in Logstash.");
            }
        } catch (InstantiationException | IllegalAccessException | ClassNotFoundException e) {
            throw new SecretStoreException.ImplementationNotFoundException(
                    String.format("Could not %s class %s, please validate the `keystore.classname` is configured correctly and that the class can be loaded by Logstash ", mode
                                    .name().toLowerCase(), className), e);
        } catch (NoSuchMethodException | InvocationTargetException e) {
            throw new SecretStoreException.ImplementationInvalidException(
                    String.format("Could not %s class %s, please validate the `keystore.classname` is configured correctly and that the class can be loaded by Logstash ", mode
                            .name().toLowerCase(), className), e);
        }
    }

    /**
     * <p>Adds the credential to the {@link SecureConfig} that is needed to access the {@link SecretStore}. Value read from environment variable "LOGSTASH_KEYSTORE_PASS"</p>
     *
     * @param secureConfig The configuration to add the secret store access
     */
    private void addSecretStoreAccess(SecureConfig secureConfig) {
        String keystore_pass = environmentVariableProvider.get(ENVIRONMENT_PASS_KEY);

        if (keystore_pass != null) {
            secureConfig.add(KEYSTORE_ACCESS_KEY, keystore_pass.toCharArray());
            keystore_pass = null;
        }
    }
}
