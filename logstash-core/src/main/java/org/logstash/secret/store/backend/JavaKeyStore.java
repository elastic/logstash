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
    private static final String KEYSTORE_TYPE = "pkcs12";
    private static final Logger LOGGER = LogManager.getLogger(JavaKeyStore.class);
    private static final String PATH_KEY = "keystore.file";
    private static final CharsetEncoder asciiEncoder = StandardCharsets.US_ASCII.newEncoder();
    private KeyStore keyStore;
    private char[] keyStorePass;
    private Path keyStorePath;
    private ProtectionParameter protectionParameter;
    private Lock readLock;
    private boolean useDefaultPass = false;
    private Lock writeLock;
    //package private for testing
    static String filePermissions = "rw-r--r--";
    private static final boolean IS_WINDOWS = System.getProperty("os.name").startsWith("Windows");

    /**
     * {@inheritDoc}
     *
     * @param config The configuration for this keystore <p>Requires "keystore.file" in the configuration,</p><p>WARNING! this method clears all values
     *               from this configuration, meaning this config is NOT reusable after passed in here.</p>
     * @throws SecretStoreException.CreateException if the store can not be created
     * @throws SecretStoreException                 (of other sub types) if contributing factors prevent the creation
     */
    @Override
    public JavaKeyStore create(SecureConfig config) {
        if (exists(config)) {
            throw new SecretStoreException.AlreadyExistsException(String.format("Logstash keystore at %s already exists.",
                    new String(config.getPlainText(PATH_KEY))));
        }
        try {
            init(config);
            writeLock.lock();
            LOGGER.debug("Creating new keystore at {}.", keyStorePath.toAbsolutePath());
            String keyStorePermissions = filePermissions;
            //create the keystore on disk with a default entry to identify this as a logstash keystore
            //can not set posix attributes on create here since not all Windows are posix, *nix will get the umask default and posix permissions will be set below
            Files.createFile(keyStorePath);
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
                LOGGER.info("Created Logstash keystore at {}", keyStorePath.toAbsolutePath());
                return this;
            } catch (Exception e) {
                throw new SecretStoreException.CreateException("Failed to create Logstash keystore.", e);
            }
        } catch (SecretStoreException sse) {
            throw sse;
        } catch (NoSuchFileException | AccessDeniedException fe) {
            throw new SecretStoreException.CreateException("Error while trying to create the Logstash keystore. Please ensure that path to " + keyStorePath.toAbsolutePath() +
                    " exists and is writable", fe);
        } catch (Exception e) { //should never happen
            throw new SecretStoreException.UnknownException("Error while trying to create the Logstash keystore. ", e);
        } finally {
            releaseLock(writeLock);
            config.clearValues();
        }
    }

    @Override
    public void delete(SecureConfig config) {
        try {
            initLocks();
            writeLock.lock();
            if (exists(config)) {
                Files.delete(Paths.get(new String(config.getPlainText(PATH_KEY))));
            }
        } catch (SecretStoreException sse) {
            throw sse;
        } catch (Exception e) { //should never happen
            throw new SecretStoreException.UnknownException("Error while trying to delete the Logstash keystore", e);
        } finally {
            releaseLock(writeLock);
            config.clearValues();
        }
    }

    /**
     * {@inheritDoc}
     *
     * @param config The configuration for this keystore <p>Requires "keystore.file" in the configuration</p>
     */
    @Override
    public boolean exists(SecureConfig config) {
        char[] path = config.getPlainText(PATH_KEY);
        if (!valid(path)) {
            LOGGER.warn("keystore.file configuration is not defined"); // should only every happen via tests
            return false;
        }
        return new File(new String(path)).exists();
    }

    @Override
    protected void finalize() throws Throwable {
        SecretStoreUtil.clearChars(keyStorePass);
    }

    /**
     * Obtains the keystore password depending on if the password is explicitly defined and/or if this is a new keystore.
     *
     * @param config the configuration
     * @return the char[] of the keystore password
     * @throws IOException on io errors
     */
    private char[] getKeyStorePassword(SecureConfig config) throws IOException {
        char[] plainText = config.getPlainText(SecretStoreFactory.KEYSTORE_ACCESS_KEY);
        boolean existing = exists(config);

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

        useDefaultPass = !config.has(SecretStoreFactory.KEYSTORE_ACCESS_KEY);

        if (useDefaultPass) {
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
            //explicit user defined pass
            //keystore passwords require ascii encoding, only base64 encode if necessary
            return asciiEncoder.canEncode(CharBuffer.wrap(plainText)) ? plainText : SecretStoreUtil.base64Encode(plainText);
        }
        throw new SecretStoreException.AccessException(
                String.format("Could not determine keystore password. Please ensure the file at %s is a valid Logstash keystore", keyStorePath.toAbsolutePath()));
    }

    private void init(SecureConfig config) throws IOException, KeyStoreException {
        char[] path = config.getPlainText(PATH_KEY);
        if (!valid(path)) {
            throw new IllegalArgumentException("Logstash keystore path must be defined");
        }
        this.keyStorePath = Paths.get(new String(path));
        this.keyStorePass = getKeyStorePassword(config);
        this.keyStore = KeyStore.getInstance(KEYSTORE_TYPE);
        this.protectionParameter = new PasswordProtection(this.keyStorePass);
        initLocks();
    }

    private void initLocks(){
        ReadWriteLock readWriteLock = new ReentrantReadWriteLock();
        readLock = readWriteLock.readLock();
        writeLock = readWriteLock.writeLock();
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
            releaseLock(readLock);
        }
        return identifiers;
    }

    /**
     * {@inheritDoc}
     *
     * @param config The configuration for this keystore <p>Requires "keystore.file" in the configuration</p><p>WARNING! this method clears all values
     *               from this configuration, meaning this config is NOT reusable after passed in here.</p>
     * @throws SecretStoreException.CreateException if the store can not be created
     * @throws SecretStoreException                 (of other sub types) if contributing factors prevent the creation
     */
    @Override
    public JavaKeyStore load(SecureConfig config) {
        if (!exists(config)) {
            throw new SecretStoreException.LoadException(
                    String.format("Can not find Logstash keystore at %s. Please verify this file exists and is a valid Logstash keystore.",
                            config.getPlainText("keystore.file") == null ? "<undefined>" : new String(config.getPlainText("keystore.file"))));
        }
        try {
            init(config);
            readLock.lock();
            try (final InputStream is = Files.newInputStream(keyStorePath)) {
                try {
                    keyStore.load(is, this.keyStorePass);
                } catch (IOException ioe) {
                    if (ioe.getCause() instanceof UnrecoverableKeyException) {
                        throw new SecretStoreException.AccessException(
                                String.format("Can not access Logstash keystore at %s. Please verify correct file permissions and keystore password.",
                                        keyStorePath.toAbsolutePath()), ioe);
                    } else {
                        throw new SecretStoreException.LoadException(String.format("Found a file at %s, but it is not a valid Logstash keystore.",
                                keyStorePath.toAbsolutePath().toString()), ioe);
                    }
                }
                byte[] marker = retrieveSecret(LOGSTASH_MARKER);
                if (marker == null) {
                    throw new SecretStoreException.LoadException(String.format("Found a keystore at %s, but it is not a Logstash keystore.",
                            keyStorePath.toAbsolutePath().toString()));
                }
                LOGGER.debug("Using existing keystore at {}", keyStorePath.toAbsolutePath());
                return this;
            }
        } catch (SecretStoreException sse) {
            throw sse;
        } catch (Exception e) { //should never happen
            throw new SecretStoreException.UnknownException("Error while trying to load the Logstash keystore", e);
        } finally {
            releaseLock(readLock);
            config.clearValues();
        }
    }

    /**
     * Need to load the keystore before any operations in case an external (or different JVM) has modified the keystore on disk.
     */
    private void loadKeyStore() throws CertificateException, NoSuchAlgorithmException, IOException {
        try (final InputStream is = Files.newInputStream(keyStorePath)) {
            keyStore.load(is, keyStorePass);
        }
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
            releaseLock(writeLock);
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
            releaseLock(writeLock);
        }
    }

    private void releaseLock(Lock lock) {
        if (lock != null) {
            lock.unlock();
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
                    LOGGER.debug("requested secret {} not found", identifier.toExternalForm());
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
                releaseLock(readLock);
            }
        }
        return null;
    }

    /**
     * Saves the keystore with some extra meta data if needed. Note - need two output streams here to allow checking the with the append flag, and the other without an append.
     */
    private void saveKeyStore() throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException {
        FileLock fileLock = null;
        try (final FileOutputStream appendOs = new FileOutputStream(keyStorePath.toFile(), true)) {
            // The keystore.store method on Windows checks for the file lock and does not allow _any_ interaction with the keystore if it is locked.
            if (!IS_WINDOWS) {
                fileLock = appendOs.getChannel().tryLock();
                if (fileLock == null) {
                    throw new IllegalStateException("Can not save Logstash keystore. Some other process has locked on the file: " + keyStorePath.toAbsolutePath());
                }
            }
            try (final OutputStream os = Files.newOutputStream(keyStorePath, StandardOpenOption.WRITE)) {
                keyStore.store(os, keyStorePass);
            }
            if (useDefaultPass) {
                byte[] obfuscatedPass = SecretStoreUtil.asciiCharToBytes(SecretStoreUtil.obfuscate(keyStorePass.clone()));
                DataOutputStream dataOutputStream = new DataOutputStream(appendOs);
                appendOs.write(obfuscatedPass);
                dataOutputStream.write(obfuscatedPass.length); // 1 byte integer
            }
        } finally {
            if (fileLock != null && fileLock.isValid()) {
                fileLock.release();
            }
        }
    }

    /**
     * @param chars char[] to check for null or empty
     * @return true if not null, and not empty, false otherwise
     */
    private boolean valid(char[] chars) {
        return !(chars == null || chars.length == 0);
    }
}

