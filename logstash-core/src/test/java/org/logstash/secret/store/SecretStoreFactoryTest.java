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

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.junit.rules.TemporaryFolder;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.backend.JavaKeyStore;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.logstash.secret.store.SecretStoreFactory.ENVIRONMENT_PASS_KEY;
import static org.logstash.secret.store.SecretStoreFactory.KEYSTORE_ACCESS_KEY;
import static org.logstash.secret.store.SecretStoreFactory.LOGSTASH_MARKER;

/**
 * Unit tests for {@link SecretStoreFactory}
 */
@SuppressWarnings({"serial", "rawtypes", "unchecked"})
public class SecretStoreFactoryTest {

    @Rule
    public TemporaryFolder folder = new TemporaryFolder();

    @Rule
    public ExpectedException thrown = ExpectedException.none();

    private static final SecretStoreFactory secretStoreFactory = SecretStoreFactory.fromEnvironment();

    @Test
    public void testAlternativeImplementation() {
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.classname", "org.logstash.secret.store.SecretStoreFactoryTest$MemoryStore".toCharArray());
        SecretStore secretStore = secretStoreFactory.load(secureConfig);
        assertThat(secretStore).isInstanceOf(MemoryStore.class);
        validateMarker(secretStore);
    }

    @Test
    public void testAlternativeImplementationInvalid() {
        thrown.expect(SecretStoreException.ImplementationNotFoundException.class);
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.classname", "junk".toCharArray());
        SecretStore secretStore = secretStoreFactory.load(secureConfig);
        assertThat(secretStore).isInstanceOf(MemoryStore.class);
        validateMarker(secretStore);
    }

    @Test
    public void testCreateLoad() throws IOException {
        SecretIdentifier id = new SecretIdentifier(UUID.randomUUID().toString());
        String value = UUID.randomUUID().toString();
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray());
        SecretStore secretStore = secretStoreFactory.create(secureConfig.clone());

        byte[] marker = secretStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
        secretStore.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        byte[] retrievedValue = secretStore.retrieveSecret(id);
        assertThat(new String(retrievedValue, StandardCharsets.UTF_8)).isEqualTo(value);


        secretStore = secretStoreFactory.load(secureConfig);
        marker = secretStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
        secretStore.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        retrievedValue = secretStore.retrieveSecret(id);
        assertThat(new String(retrievedValue, StandardCharsets.UTF_8)).isEqualTo(value);
    }

    @Test
    public void testDefaultLoadWithEnvPass() throws Exception {
        String pass = UUID.randomUUID().toString();
        final Map<String,String> modifiedEnvironment = new HashMap<String,String>(System.getenv()) {{
            put(ENVIRONMENT_PASS_KEY, pass);
        }};

        final SecretStoreFactory secretStoreFactory = SecretStoreFactory.withEnvironment(modifiedEnvironment);

        //Each usage of the secure config requires it's own instance since implementations can/should clear all the values once used.
        SecureConfig secureConfig1 = new SecureConfig();
        secureConfig1.add("keystore.file", folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray());
        SecureConfig secureConfig2 = secureConfig1.clone();
        SecureConfig secureConfig3 = secureConfig1.clone();
        SecureConfig secureConfig4 = secureConfig1.clone();

        //ensure that with only the environment we can retrieve the marker from the store
        SecretStore secretStore = secretStoreFactory.create(secureConfig1);
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
        secretStore = secretStoreFactory.load(secureConfig4);
        validateMarker(secretStore);
    }

    /**
     * Ensures that load failure is the correct type.
     */
    @Test
    public void testErrorLoading() {
        thrown.expect(SecretStoreException.LoadException.class);
        //default implementation requires a path
        secretStoreFactory.load(new SecureConfig());
    }

    private void validateMarker(SecretStore secretStore) {
        byte[] marker = secretStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
    }

    /**
     * Valid alternate implementation
     */
    public static class MemoryStore implements SecretStore {

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
        public boolean containsSecret(SecretIdentifier id) { return secrets.containsKey(id); }

        @Override
        public byte[] retrieveSecret(SecretIdentifier id) {
            ByteBuffer bb = secrets.get(id);
            return bb != null ? bb.array() : null;
        }
    }

}