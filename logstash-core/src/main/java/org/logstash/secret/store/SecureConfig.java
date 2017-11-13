package org.logstash.secret.store;

import java.nio.CharBuffer;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A String to char[] container that holds a referenced char[] obfuscated in memory and allows for easy clearing all values from memory.
 */
public class SecureConfig {

    private Map<String, CharBuffer> config = new ConcurrentHashMap<>();

    //package private for testing
    volatile boolean cleared;

    /**
     * adds a value to the secure config
     *
     * @param key   the reference to the configuration value
     * @param value the configuration value
     * @throws IllegalStateException if this configuration has been cleared
     */
    public void add(String key, char[] value) {
        if(cleared){
            throw new IllegalStateException("This configuration has been cleared and can not be re-used.");
        }
        config.put(key, CharBuffer.wrap(SecretStoreUtil.obfuscate(value)));
    }

    /**
     * Zero outs all internally held char[]
     */
    public void clearValues() {
        config.forEach((k, v) -> SecretStoreUtil.clearChars(v.array()));
        cleared = true;
    }

    /**
     * Creates a full clone of this object.
     *
     * @return a copy of this {@link SecureConfig}
     * @throws IllegalStateException if this configuration has been cleared
     */
    public SecureConfig clone() {
        if(cleared){
            throw new IllegalStateException("This configuration has been cleared and can not be re-used.");
        }
        SecureConfig clone = new SecureConfig();
        config.forEach((k, v) -> clone.add(k, SecretStoreUtil.deObfuscate(v.array().clone())));
        return clone;
    }

    /**
     * Retrieve the un-obfuscated value
     *
     * @param key the reference to the configuration value
     * @return the un-obfuscated configuration value.
     */
    public char[] getPlainText(String key) {
        if(cleared){
            throw new IllegalStateException("This configuration has been cleared and can not be re-used.");
        }
        return config.get(key) == null ? null : SecretStoreUtil.deObfuscate(config.get(key).array().clone());
    }

    /**
     * Determine if a value for this key exists. No guarantees if the value has been zero'ed (cleared) or not.
     *
     * @param key the reference to the configuration value.
     * @return true if this key has ever been added, false otherwise
     */
    public boolean has(String key) {
        return config.get(key) != null;
    }

}
