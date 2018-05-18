package org.logstash.secret;

import org.logstash.secret.store.SecretStore;
import org.logstash.secret.store.SecureConfig;

import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import static org.logstash.secret.store.SecretStoreFactory.LOGSTASH_MARKER;

/**
 * Valid alternate implementation of secret store
 */
public class MemoryStore implements SecretStore {

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
