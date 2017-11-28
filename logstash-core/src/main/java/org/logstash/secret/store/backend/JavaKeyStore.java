package org.logstash.secret.store.backend;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.*;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.io.*;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.channels.FileLock;
import java.nio.channels.SeekableByteChannel;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.nio.file.attribute.PosixFileAttributeView;
import java.nio.file.attribute.PosixFilePermissions;
import java.security.KeyStore;
import java.security.KeyStore.PasswordProtection;
import java.security.KeyStore.ProtectionParameter;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.util.*;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import static org.logstash.secret.store.SecretStoreFactory.LOGSTASH_MARKER;

/**
 * <p>Java Key Store implementation for the {@link SecretStore}.</p>
 * <p>Note this implementation should not be used for high volume or large datasets.</p>
 * <p>This class is threadsafe.</p>
 */
public final class JavaKeyStore implements SecretStore {
    private static final Logger LOGGER = LogManager.getLogger(JavaKeyStore.class);
    private static final String KEYSTORE_TYPE = "pkcs12";
    private static final CharsetEncoder asciiEncoder = StandardCharsets.US_ASCII.newEncoder();

    private char[] keyStorePass;
    private Path keyStorePath;
    private final ProtectionParameter protectionParameter;
    private final Lock readLock;
    private final Lock writeLock;
    private KeyStore keyStore;
    private final SecureConfig config;

    /**
     * Constructor - will create the keystore if it does not exist.
     *
     * @param config The configuration for this keystore <p>Requires "keystore.pass" and "keystore.path" in the configuration</p><p>WARNING! this constructor clears all values
     *               from this configuration, meaning this config is NOT reusable after passed in here.</p>
     * @throws SecretStoreException if errors occur while trying to create or access the keystore
     */
    public JavaKeyStore(SecureConfig config) {
        this.config = config;
        try {
            char[] path = config.getPlainText("keystore.path");
            if (path == null) {
                throw new IllegalArgumentException("Logstash keystore path must be defined");
            }
            this.keyStorePath = Paths.get(new String(path));
            this.keyStorePass = getKeyStorePassword(keyStorePath.toFile().exists());
            this.keyStore = KeyStore.getInstance(KEYSTORE_TYPE);

            ReadWriteLock readWriteLock = new ReentrantReadWriteLock();
            readLock = readWriteLock.readLock();
            writeLock = readWriteLock.writeLock();
            this.protectionParameter = new PasswordProtection(this.keyStorePass);

            try (final InputStream is = Files.newInputStream(keyStorePath)) {
                try {
                    keyStore.load(is, this.keyStorePass);
                } catch (IOException ioe) {
                    if (ioe.getCause() instanceof UnrecoverableKeyException) {
                        throw new SecretStoreException.AccessException(
                                String.format("Can not access Java keystore at %s. Please verify correct file permissions and keystore password.",
                                        keyStorePath.toAbsolutePath()), ioe);
                    } else {
                        throw new SecretStoreException.NotLogstashKeyStore(String.format("Found a file at %s, but it is not a valid Logstash keystore.",
                                keyStorePath.toAbsolutePath().toString()), ioe);
                    }
                }
                byte[] marker = retrieveSecret(LOGSTASH_MARKER);
                if (marker == null) {
                    throw new SecretStoreException.NotLogstashKeyStore(String.format("Found a keystore at %s, but it is not a Logstash keystore.",
                            keyStorePath.toAbsolutePath().toString()));
                }
                LOGGER.debug("Using existing keystore at {}", keyStorePath.toAbsolutePath());
            } catch (NoSuchFileException noSuchFileException) {
                LOGGER.info("Keystore not found at {}. Creating new keystore.", keyStorePath.toAbsolutePath());
                //wrapped in a system property mostly for testing, but could be used for more restrictive defaults
                String keyStorePermissions = System.getProperty("logstash.keystore.file.perms", "rw-rw----");
                //create the keystore on disk with a default entry to identify this as a logstash keystore
                Files.createFile(keyStorePath, PosixFilePermissions.asFileAttribute(PosixFilePermissions.fromString(keyStorePermissions)));
                try {
                    keyStore = KeyStore.Builder.newInstance(KEYSTORE_TYPE, null, protectionParameter).getKeyStore();
                    SecretKeyFactory factory = SecretKeyFactory.getInstance("PBE");
                    byte[] base64 = SecretStoreUtil.base64Encode(LOGSTASH_MARKER.getKey().getBytes(StandardCharsets.UTF_8));
                    SecretKey secretKey = factory.generateSecret(new PBEKeySpec(SecretStoreUtil.asciiBytesToChar(base64)));
                    keyStore.setEntry(LOGSTASH_MARKER.toExternalForm(), new KeyStore.SecretKeyEntry(secretKey), protectionParameter);
                    saveKeyStore();
                    PosixFileAttributeView attrs = Files.getFileAttributeView(keyStorePath, PosixFileAttributeView.class);
                    if (attrs != null) {
                        //the directory umask applies when creating the file, so re-apply permissions here
                        attrs.setPermissions(PosixFilePermissions.fromString(keyStorePermissions));
                    }
                    LOGGER.info("Keystore created at {}", keyStorePath.toAbsolutePath());
                } catch (Exception e) {
                    throw new SecretStoreException.CreateException("Failed to create Logstash keystore.", e);
                }
            }
        } catch (SecretStoreException sse) {
            throw sse;
        } catch (Exception e) { //should never happen
            throw new SecretStoreException.UnknownException("Error while trying to create or load the Logstash keystore", e);
        } finally {
            config.clearValues();
        }
    }

    /**
     * Obtains the keystore password depending on if the password is explicitly defined and/or if this is a new keystore.
     *
     * @param existing true if the keystore file already exists
     * @return the char[] of the keystore password
     * @throws IOException on io errors
     */
    private char[] getKeyStorePassword(boolean existing) throws IOException {
        char[] plainText = config.getPlainText(SecretStoreFactory.KEYSTORE_ACCESS_KEY);

        //ensure if a password is configured, that we don't allow empty passwords
        if (config.has(SecretStoreFactory.KEYSTORE_ACCESS_KEY) && (plainText == null || plainText.length == 0)) {
            String message = String.format("Empty keystore passwords are not allowed. Please ensure configured password is not empty for Logstash keystore %s.",
                    keyStorePath.toAbsolutePath());
            if (existing) {
                throw new SecretStoreException.AccessException(message);
            } else {
                throw new SecretStoreException.CreateException(message);
            }
        }

        if (plainText == null) {
            if (existing) {
                //read the pass
                SeekableByteChannel byteChannel = Files.newByteChannel(keyStorePath, StandardOpenOption.READ);
                if (byteChannel.size() > 1) {
                    byteChannel.position(byteChannel.size() - 1);
                    ByteBuffer byteBuffer = ByteBuffer.allocate(1);
                    byteChannel.read(byteBuffer);
                    int size = byteBuffer.array()[0] & 0xff;
                    if (size > 0 && byteChannel.size() >= size + 1) {
                        byteBuffer = ByteBuffer.allocate(size);
                        byteChannel.position(byteChannel.size() - size - 1);
                        byteChannel.read(byteBuffer);
                        return SecretStoreUtil.deObfuscate(SecretStoreUtil.asciiBytesToChar(byteBuffer.array()));
                    }
                }
            } else {
                //create the pass
                byte[] randomBytes = new byte[32];
                new Random().nextBytes(randomBytes);
                return SecretStoreUtil.base64EncodeToChars(randomBytes);
            }
        } else {
            //keystore passwords require ascii encoding, only base64 encode if necessary
            return asciiEncoder.canEncode(CharBuffer.wrap(plainText)) ? plainText : SecretStoreUtil.base64Encode(plainText);
        }
        throw new SecretStoreException.AccessException(
                String.format("Could not determine keystore password. Please ensure the file at %s is a valid Logstash keystore", keyStorePath.toAbsolutePath()));
    }

    @Override
    public Collection<SecretIdentifier> list() {
        Set<SecretIdentifier> identifiers = new HashSet<>();
        try {
            readLock.lock();
            loadKeyStore();
            Enumeration<String> aliases = keyStore.aliases();
            while (aliases.hasMoreElements()) {
                String alias = aliases.nextElement();
                identifiers.add(SecretIdentifier.fromExternalForm(alias));
            }
        } catch (Exception e) {
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
            loadKeyStore();
            SecretKeyFactory factory = SecretKeyFactory.getInstance("PBE");
            //PBEKey requires an ascii password, so base64 encode it
            byte[] base64 = SecretStoreUtil.base64Encode(secret);
            PBEKeySpec passwordBasedKeySpec = new PBEKeySpec(SecretStoreUtil.asciiBytesToChar(base64));
            SecretKey secretKey = factory.generateSecret(passwordBasedKeySpec);
            keyStore.setEntry(identifier.toExternalForm(), new KeyStore.SecretKeyEntry(secretKey), protectionParameter);
            try {
                saveKeyStore();
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
            loadKeyStore();
            keyStore.deleteEntry(identifier.toExternalForm());
            saveKeyStore();
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
                loadKeyStore();
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
            } catch (Exception e) {
                throw new SecretStoreException.RetrievalException(identifier, e);
            } finally {
                readLock.unlock();
            }
        }
        return null;
    }

    /**
     * Need to reload the keystore before any operations in case an external (or different JVM)  has modified the keystore on disk.
     */
    private void loadKeyStore() throws CertificateException, NoSuchAlgorithmException, IOException {
        try (final InputStream is = Files.newInputStream(keyStorePath)) {
            keyStore.load(is, keyStorePass);
        }
    }

    /**
     * Saves the keystore with some extra meta data if needed. Note - need two output streams here to allow checking the with the append flag, and the other without an append.
     */
    private void saveKeyStore() throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException {
        FileLock fileLock = null;
        try (final FileOutputStream appendOs = new FileOutputStream(keyStorePath.toFile(), true)) {
            fileLock = appendOs.getChannel().tryLock();
            if (fileLock == null) {
                throw new IllegalStateException("Can not save Logstash keystore. Some other process has a lock on the file: " + keyStorePath.toAbsolutePath());
            }
            try (final OutputStream os = Files.newOutputStream(keyStorePath, StandardOpenOption.WRITE)) {
                keyStore.store(os, keyStorePass);
                if (!config.has(SecretStoreFactory.KEYSTORE_ACCESS_KEY)) {
                    byte[] obfuscatedPass = SecretStoreUtil.asciiCharToBytes(SecretStoreUtil.obfuscate(keyStorePass.clone()));
                    DataOutputStream dataOutputStream = new DataOutputStream(os);
                    os.write(obfuscatedPass);
                    dataOutputStream.write(obfuscatedPass.length); // 1 byte integer
                }
            } finally {
                if (fileLock != null) {
                    fileLock.release();
                }
            }
        }
    }

    @Override
    protected void finalize() throws Throwable {
        SecretStoreUtil.clearChars(keyStorePass);
    }
}

