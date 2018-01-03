package org.logstash.secret.store;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.SecretIdentifier;

/**
 * <p>A factory to load the implementation of a {@link SecretStore}. Implementation may be defined via the {@link SecureConfig} via with a key of "keystore.classname" and
 * value equal to the fqn of the class that implements {@link SecretStore}
 * </p>
 */
public class SecretStoreFactory {

    public static final String KEYSTORE_ACCESS_KEY = "keystore.pass";
    //secret stores should create a secret with this as the key and value to identify a logstash secret
    public final static SecretIdentifier LOGSTASH_MARKER = new SecretIdentifier("keystore.seed");

    public final static String ENVIRONMENT_PASS_KEY = "LOGSTASH_KEYSTORE_PASS";

    /**
     * Private constructor
     */
    private SecretStoreFactory() {
    }

    private static final Logger LOGGER = LogManager.getLogger(SecretStoreFactory.class);

    private enum MODE {LOAD, CREATE, EXISTS, DELETE}

    /**
     * Determine if this secret store currently exists
     * @return true if the secret store exists, false otherwise
     */
    public static boolean exists(SecureConfig secureConfig) {
        return doIt(MODE.EXISTS, secureConfig).exists(secureConfig);
    }

    /**
     * Creates a new {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * @return the newly created SecretStore, throws {@link SecretStoreException} if errors occur while loading, or if store already exists
     */
    static public SecretStore create(SecureConfig secureConfig) {
        return doIt(MODE.CREATE, secureConfig);
    }

    /**
     * Deletes a {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * throws {@link SecretStoreException} if errors occur
     */
    static public void delete(SecureConfig secureConfig) {
        doIt(MODE.DELETE, secureConfig);
    }

    /**
     * Loads an existing {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * @return the loaded SecretStore, throws {@link SecretStoreException} if errors occur while loading, or if store does not exist
     */
    static public SecretStore load(SecureConfig secureConfig) {
        return doIt(MODE.LOAD, secureConfig);
    }

    @SuppressWarnings({"unchecked", "JavaReflectionMemberAccess"})
    private static SecretStore doIt(MODE mode, SecureConfig secureConfig) {
        char[] configuredClassName = secureConfig.getPlainText("keystore.classname");
        String className = configuredClassName != null ? new String(configuredClassName) : "org.logstash.secret.store.backend.JavaKeyStore";
        try {
            LOGGER.debug("Attempting to {} or secret store with implementation: {}", mode.name().toLowerCase(), className);
            Class<? extends SecretStore> implementation = (Class<? extends SecretStore>) Class.forName(className);

            addSecretStoreAccess(secureConfig);

            if (MODE.LOAD.equals(mode)) {
                return implementation.newInstance().load(secureConfig);
            } else if (MODE.CREATE.equals(mode)) {
                return implementation.newInstance().create(secureConfig);
            } else if (MODE.DELETE.equals(mode)) {
                implementation.newInstance().delete(secureConfig);
                return null;
            } else if (MODE.EXISTS.equals(mode)) {
                return implementation.newInstance();
            } else {
                throw new IllegalStateException("missing mode. This is bug in Logstash.");
            }
        } catch (InstantiationException | IllegalAccessException | ClassNotFoundException e) {
            throw new SecretStoreException.ImplementationNotFoundException(
                    String.format("Could not %s class %s, please validate the `keystore.classname` is configured correctly and that the class can be loaded by Logstash ", mode
                                    .name().toLowerCase(), className), e);
        }
    }

    /**
     * <p>Adds the credential to the {@link SecureConfig} that is needed to access the {@link SecretStore}. Value read from environment variable "LOGSTASH_KEYSTORE_PASS"</p>
     *
     * @param secureConfig The configuration to add the secret store access
     */
    private static void addSecretStoreAccess(SecureConfig secureConfig) {
        String environment = System.getenv(ENVIRONMENT_PASS_KEY);

        char[] pass = null;
        if (environment != null) {
            secureConfig.add(KEYSTORE_ACCESS_KEY, environment.toCharArray());
            environment = null;
        }

        //futile attempt to remove the original pass from memory
        System.gc();
    }
}
