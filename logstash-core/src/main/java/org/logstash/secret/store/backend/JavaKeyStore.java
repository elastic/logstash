package org.logstash.secret.store.backend;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.SecretStore;
import org.logstash.secret.store.SecretStoreException;
import org.logstash.secret.store.SecretStoreUtil;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFileAttributeView;
import java.nio.file.attribute.PosixFilePermissions;
import java.security.KeyStore;
import java.security.KeyStore.PasswordProtection;
import java.security.KeyStore.ProtectionParameter;
import java.security.KeyStoreException;
import java.security.UnrecoverableKeyException;
import java.util.*;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * <p>Java Key Store implementation for the {@link SecretStore}.</p>
 * <p>Note this implementation should not be used for high volume or large datasets.</p>
 * <p>This class is threadsafe.</p>
 */
public final class JavaKeyStore implements SecretStore {
    public static final String LOGSTASH_MARKER = "logstash-key-store";
    private static final Logger LOGGER = LogManager.getLogger(JavaKeyStore.class);
    private static final String KEYSTORE_TYPE = "pkcs12";

    private final char[] keyStorePass;
    private final Path keyStorePath;
    private final ProtectionParameter protectionParameter;
    private final Lock readLock;
    private final Lock writeLock;
    private KeyStore keyStore;

    /**
     * Constructor - will create the keystore if it does not exist
     *
     * @param keyStorePath The full path to the java keystore
     * @param keyStorePass The password to the keystore
     * @throws SecretStoreException if errors occur while trying to create or access the keystore
     */
    public JavaKeyStore(Path keyStorePath, char[] keyStorePass) {
        try {
            this.keyStorePath = keyStorePath;
            this.keyStore = KeyStore.getInstance(KEYSTORE_TYPE);
            this.keyStorePass = SecretStoreUtil.base64Encode(keyStorePass);
            ReadWriteLock readWriteLock = new ReentrantReadWriteLock();
            readLock = readWriteLock.readLock();
            writeLock = readWriteLock.writeLock();
            this.protectionParameter = new PasswordProtection(this.keyStorePass);
            SecretIdentifier logstashMarker = new SecretIdentifier(LOGSTASH_MARKER);

            try (final InputStream is = Files.newInputStream(keyStorePath)) {
                try {
                    keyStore.load(is, this.keyStorePass);
                } catch (IOException ioe) {
                    if (ioe.getCause() instanceof UnrecoverableKeyException) {
                        throw new SecretStoreException.AccessException(
                                String.format("Can not access Java keystore at %s, check file permissions and the keystore password", keyStorePath.toAbsolutePath
                                        ()), ioe);
                    } else {
                        throw new SecretStoreException.NotLogstashKeyStore(String.format("Found a file at %s, but it is not a valid logstash keystore.",
                                keyStorePath.toAbsolutePath().toString()), ioe);
                    }
                }
                byte[] marker = retrieveSecret(logstashMarker);
                if (marker == null) {
                    throw new SecretStoreException.NotLogstashKeyStore(String.format("Found a keystore at %s, but it is not a logstash keystore.",
                            keyStorePath.toAbsolutePath().toString()));
                }
                LOGGER.debug("Using existing keystore at {}", keyStorePath.toAbsolutePath().toString());
            } catch (NoSuchFileException noSuchFileException) {
                LOGGER.info("Keystore not found at {}. Creating new keystore.", keyStorePath.toAbsolutePath().toString());
                //create the keystore on disk with a default entry to identify this as a logstash keystore
                try (final OutputStream os = Files.newOutputStream(keyStorePath)) {
                    keyStore = KeyStore.Builder.newInstance(KEYSTORE_TYPE, null, protectionParameter).getKeyStore();
                    SecretKeyFactory factory = SecretKeyFactory.getInstance("PBE");
                    byte[] base64 = SecretStoreUtil.base64Encode(LOGSTASH_MARKER.getBytes(StandardCharsets.UTF_8));
                    SecretKey secretKey = factory.generateSecret(new PBEKeySpec(SecretStoreUtil.asciiBytesToChar(base64)));
                    keyStore.setEntry(logstashMarker.toExternalForm(), new KeyStore.SecretKeyEntry(secretKey), protectionParameter);
                    keyStore.store(os, this.keyStorePass);

                    PosixFileAttributeView attrs = Files.getFileAttributeView(keyStorePath, PosixFileAttributeView.class);
                    if (attrs != null) {
                        try {
                            //wrapped in a system mostly for testing, but could be used for more restrictive defaults
                            attrs.setPermissions(PosixFilePermissions.fromString(System.getProperty("logstash.keystore.java.file.perms", "rw-rw----")));
                        } catch (Exception e) {
                            try {
                                Files.delete(keyStorePath);
                            } catch (IOException ioe) {
                                //do nothing
                            }
                            throw new SecretStoreException.CreateException("Error can not set file permissions on Java keystore", e);
                        }
                    }
                    LOGGER.info("Keystore created at {}", keyStorePath.toAbsolutePath().toString());
                } catch (Exception e) {
                    throw new SecretStoreException.CreateException("Error can not create Java keystore", e);
                }
            }
        } catch (SecretStoreException sse) {
            throw sse;
        } catch (Exception e) { //should never happen
            throw new SecretStoreException("Error while trying to create or launch the JavaKeyStore", e);
        }
    }

    @Override
    public Collection<SecretIdentifier> list() {
        Set<SecretIdentifier> identifiers = new HashSet<>();
        try {
            readLock.lock();
            Enumeration<String> aliases = keyStore.aliases();
            while (aliases.hasMoreElements()) {
                String alias = aliases.nextElement();
                identifiers.add(SecretIdentifier.fromExternalForm(alias));
            }
        } catch (KeyStoreException e) {
            throw new SecretStoreException.ListException(e);
        } finally {
            readLock.unlock();
        }
        return identifiers;
    }

    @Override
    public void persistSecret(SecretIdentifier identifier, byte[] secret) {
        try {
            writeLock.lock();
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBE");
            //PBEKey requires an ascii password, so base64 encode it
            byte[] base64 = SecretStoreUtil.base64Encode(secret);
            PBEKeySpec passwordBasedKeySpec = new PBEKeySpec(SecretStoreUtil.asciiBytesToChar(base64));
            SecretKey secretKey = factory.generateSecret(passwordBasedKeySpec);
            keyStore.setEntry(identifier.toExternalForm(), new KeyStore.SecretKeyEntry(secretKey), protectionParameter);
            try (final OutputStream os = Files.newOutputStream(keyStorePath)) {
                keyStore.store(os, keyStorePass);
            } finally {
                passwordBasedKeySpec.clearPassword();
                SecretStoreUtil.clearBytes(secret);
            }
            LOGGER.debug("persisted secret {}", identifier.toExternalForm());
        } catch (Exception e) {
            throw new SecretStoreException.PersistException(identifier, e);
        } finally {
            writeLock.unlock();
        }
    }

    @Override
    public void purgeSecret(SecretIdentifier identifier) {
        try {
            writeLock.lock();
            try (final InputStream is = Files.newInputStream(keyStorePath)) {
                keyStore.load(is, keyStorePass);
                keyStore.deleteEntry(identifier.toExternalForm());
            }
            try (final OutputStream os = Files.newOutputStream(keyStorePath)) {
                keyStore.store(os, keyStorePass);
            }
            LOGGER.debug("purged secret {}", identifier.toExternalForm());
        } catch (Exception e) {
            throw new SecretStoreException.PurgeException(identifier, e);
        } finally {
            writeLock.unlock();
        }
    }

    @Override
    public byte[] retrieveSecret(SecretIdentifier identifier) {
        if (identifier != null && identifier.getKey() != null && !identifier.getKey().isEmpty()) {
            try {
                readLock.lock();
                try (final InputStream is = Files.newInputStream(keyStorePath)) {
                    keyStore.load(is, keyStorePass);
                    SecretKeyFactory factory = SecretKeyFactory.getInstance("PBE");
                    KeyStore.SecretKeyEntry secretKeyEntry = (KeyStore.SecretKeyEntry) keyStore.getEntry(identifier.toExternalForm(), protectionParameter);
                    //not found
                    if (secretKeyEntry == null) {
                        LOGGER.warn("requested secret {} not found", identifier.toExternalForm());
                        return null;
                    }
                    PBEKeySpec passwordBasedKeySpec = (PBEKeySpec) factory.getKeySpec(secretKeyEntry.getSecretKey(), PBEKeySpec.class);
                    //base64 encoded char[]
                    char[] base64secret = passwordBasedKeySpec.getPassword();
                    byte[] secret = SecretStoreUtil.base64Decode(base64secret);
                    passwordBasedKeySpec.clearPassword();
                    LOGGER.debug("retrieved secret {}", identifier.toExternalForm());
                    return secret;
                }
            } catch (Exception e) {
                throw new SecretStoreException.RetrievalException(identifier, e);
            } finally {
                readLock.unlock();
            }
        }
        return null;
    }
}

