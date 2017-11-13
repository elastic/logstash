package org.logstash.secret.store;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.SecretIdentifier;

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

/**
 * <p>A factory to load the implementation of a {@link SecretStore}. Where the implementation requires a constructor that accepts a {@link SecureConfig} as it's only parameter.
 * </p>
 */
public class SecretStoreFactory {

    public static final String KEYSTORE_ACCESS_KEY = "keystore.pass";
    //secret stores should create a secret with this as the key and value to identify a logstash secret
    public final static SecretIdentifier LOGSTASH_MARKER = new SecretIdentifier("logstash-secret-store");

    public final static String SYSTEM_PROPERTY_PASS_KEY = "logstash.keystore.pass";
    public final static String ENVIRONMENT_PASS_KEY = "LOGSTASH_KEYSTORE_PASS";

    /**
     * Private constructor
     */
    private SecretStoreFactory() {
    }

    private static final Logger LOGGER = LogManager.getLogger(SecretStoreFactory.class);

    /**
     * Creates a {@link SecretStore} based on the provided configuration
     *
     * @param secureConfig The configuration to pass to the implementation
     * @return
     */
    @SuppressWarnings({"unchecked", "JavaReflectionMemberAccess"})
    static public SecretStore loadSecretStore(SecureConfig secureConfig) {
        //cheap SPI, if we ever support more then one implementation we should expose it as a setting and push the class name here via the secureConfig
        String className = System.getProperty("org.logstash.secret.store.SecretStore", "org.logstash.secret.store.backend.JavaKeyStore");
        try {
            LOGGER.debug("Attempting to loadSecretStore secret store with implementation: {}", className);
            Class<? extends SecretStore> implementation = (Class<? extends SecretStore>) Class.forName(className);
            Constructor<? extends SecretStore> constructor = implementation.getConstructor(SecureConfig.class);
            addSecretStoreAccess(secureConfig);
            return constructor.newInstance(secureConfig);
        } catch (InstantiationException | IllegalAccessException | ClassNotFoundException | NoSuchMethodException e) {
            throw new SecretStoreException.ImplementationNotFoundException(
                    String.format("Could not loadSecretStore class %s, please ensure it is on the Java classpath, implements org.logstash.secret.store.SecretStore, and has a 1 " +
                            "argument constructor that accepts a org.logstash.secret.store.SecureConfig", className), e);
        } catch (InvocationTargetException ite) {
            //this is thrown if an exception is thrown from the constructor
            throw new SecretStoreException.LoadException("Unable to load Logstash secret store", ite);
        }
    }

    /**
     * <p>Adds the credential to the {@link SecureConfig} that is needed to access the {@link SecretStore}. The credential is searched for in the following order:</p>
     * <ul>
     * <li>Java System Property "logstash.keystore.pass" </li>
     * <li>Environment variable "LOGSTASH_KEYSTORE_PASS"</li>
     * </ul>
     *
     * @param secureConfig The configuration to add the secret store access
     */
    private static void addSecretStoreAccess(SecureConfig secureConfig) {
        String systemProperty = System.getProperty(SYSTEM_PROPERTY_PASS_KEY);
        String environment = System.getenv(ENVIRONMENT_PASS_KEY);

        char[] pass = null;
        if (systemProperty != null) {
            secureConfig.add(KEYSTORE_ACCESS_KEY, systemProperty.toCharArray());
            systemProperty = null;
        } else if (environment != null) {
            secureConfig.add(KEYSTORE_ACCESS_KEY, environment.toCharArray());
            environment = null;
        }

        //futile attempt to remove the original pass from memory
        System.gc();
    }

}
