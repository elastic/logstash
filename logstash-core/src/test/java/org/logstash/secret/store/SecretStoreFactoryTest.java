package org.logstash.secret.store;

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.junit.rules.TemporaryFolder;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.backend.JavaKeyStore;

import java.io.IOException;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.logstash.secret.store.SecretStoreFactory.*;

/**
 * Unit tests for {@link SecretStoreFactory}
 */
public class SecretStoreFactoryTest {

    @Rule
    public TemporaryFolder folder = new TemporaryFolder();

    @Rule
    public ExpectedException thrown = ExpectedException.none();

    //exact copy from https://stackoverflow.com/questions/318239/how-do-i-set-environment-variables-from-java
    //thanks @pushy and @Edward Campbell !
    @SuppressWarnings("unchecked")
    private static void setEnv(Map<String, String> newenv) throws Exception {
        try {
            Class<?> processEnvironmentClass = Class.forName("java.lang.ProcessEnvironment");
            Field theEnvironmentField = processEnvironmentClass.getDeclaredField("theEnvironment");
            theEnvironmentField.setAccessible(true);
            Map<String, String> env = (Map<String, String>) theEnvironmentField.get(null);
            env.putAll(newenv);
            Field theCaseInsensitiveEnvironmentField = processEnvironmentClass.getDeclaredField("theCaseInsensitiveEnvironment");
            theCaseInsensitiveEnvironmentField.setAccessible(true);
            Map<String, String> cienv = (Map<String, String>) theCaseInsensitiveEnvironmentField.get(null);
            cienv.putAll(newenv);
        } catch (NoSuchFieldException e) {
            Class[] classes = Collections.class.getDeclaredClasses();
            Map<String, String> env = System.getenv();
            for (Class cl : classes) {
                if ("java.util.Collections$UnmodifiableMap".equals(cl.getName())) {
                    Field field = cl.getDeclaredField("m");
                    field.setAccessible(true);
                    Object obj = field.get(env);
                    Map<String, String> map = (Map<String, String>) obj;
                    map.clear();
                    map.putAll(newenv);
                }
            }
        }
    }

    @Test
    public void testAlternativeImplementation() {
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.classname", "org.logstash.secret.store.SecretStoreFactoryTest$MemoryStore".toCharArray());
        SecretStore secretStore = SecretStoreFactory.load(secureConfig);
        assertThat(secretStore).isInstanceOf(MemoryStore.class);
        validateMarker(secretStore);
    }

    @Test
    public void testAlternativeImplementationInvalid() {
        thrown.expect(SecretStoreException.ImplementationNotFoundException.class);
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.classname", "junk".toCharArray());
        SecretStore secretStore = SecretStoreFactory.load(secureConfig);
        assertThat(secretStore).isInstanceOf(MemoryStore.class);
        validateMarker(secretStore);
    }

    @Test
    public void testCreateLoad() throws IOException {
        SecretIdentifier id = new SecretIdentifier(UUID.randomUUID().toString());
        String value = UUID.randomUUID().toString();
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray());
        SecretStore secretStore = SecretStoreFactory.create(secureConfig.clone());

        byte[] marker = secretStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
        secretStore.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        byte[] retrievedValue = secretStore.retrieveSecret(id);
        assertThat(new String(retrievedValue, StandardCharsets.UTF_8)).isEqualTo(value);


        secretStore = SecretStoreFactory.load(secureConfig);
        marker = secretStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
        secretStore.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        retrievedValue = secretStore.retrieveSecret(id);
        assertThat(new String(retrievedValue, StandardCharsets.UTF_8)).isEqualTo(value);
    }

    @Test
    public void testDefaultLoadWithEnvPass() throws Exception {
        Map<String, String> beforeEnvironment = System.getenv();
        try {

            String pass = UUID.randomUUID().toString();
            setEnv(new HashMap<String, String>() {{
                put(ENVIRONMENT_PASS_KEY, pass);
            }});

            //Each usage of the secure config requires it's own instance since implementations can/should clear all the values once used.
            SecureConfig secureConfig1 = new SecureConfig();
            secureConfig1.add("keystore.file", folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray());
            SecureConfig secureConfig2 = secureConfig1.clone();
            SecureConfig secureConfig3 = secureConfig1.clone();
            SecureConfig secureConfig4 = secureConfig1.clone();

            //ensure that with only the environment we can retrieve the marker from the store
            SecretStore secretStore = SecretStoreFactory.create(secureConfig1);
            validateMarker(secretStore);

            //ensure that aren't simply using the defaults
            boolean expectedException = false;
            try {
                new JavaKeyStore().create(secureConfig2);
            } catch (SecretStoreException e) {
                expectedException = true;
            }
            assertThat(expectedException).isTrue();

            //ensure that direct key access using the system key wil work
            secureConfig3.add(KEYSTORE_ACCESS_KEY, pass.toCharArray());
            secretStore = new JavaKeyStore().load(secureConfig3);
            validateMarker(secretStore);

            //ensure that pass will work again
            secretStore = SecretStoreFactory.load(secureConfig4);
            validateMarker(secretStore);

        } finally {
            setEnv(new HashMap<>(beforeEnvironment));
        }
    }

    /**
     * Ensures that load failure is the correct type.
     */
    @Test
    public void testErrorLoading() {
        thrown.expect(SecretStoreException.InvalidConfigurationException.class);
        //default implementation requires a path
        SecretStoreFactory.load(new SecureConfig());
    }

    private void validateMarker(SecretStore secretStore) {
        byte[] marker = secretStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
    }

    /**
     * Valid alternate implementation
     */
    static class MemoryStore implements SecretStore {

        Map<SecretIdentifier, ByteBuffer> secrets = new HashMap(1);

        public MemoryStore() {
            persistSecret(LOGSTASH_MARKER, LOGSTASH_MARKER.getKey().getBytes(StandardCharsets.UTF_8));
        }

        @Override
        public SecretStore create(SecureConfig secureConfig) {
            return this;
        }

        @Override
        public void delete(SecureConfig secureConfig) {
            secrets.clear();
        }

        @Override
        public SecretStore load(SecureConfig secureConfig) {
            return this;
        }

        @Override
        public boolean exists(SecureConfig secureConfig) {
            return true;
        }

        @Override
        public Collection<SecretIdentifier> list() {
            return secrets.keySet();
        }

        @Override
        public void persistSecret(SecretIdentifier id, byte[] secret) {
            secrets.put(id, ByteBuffer.wrap(secret));
        }

        @Override
        public void purgeSecret(SecretIdentifier id) {
            secrets.remove(id);
        }

        @Override
        public byte[] retrieveSecret(SecretIdentifier id) {
            return secrets.get(id).array();
        }
    }

}