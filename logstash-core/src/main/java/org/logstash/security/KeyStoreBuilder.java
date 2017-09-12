package org.logstash.security;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.net.ssl.KeyManagerFactory;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.*;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.spec.InvalidKeySpecException;
import java.util.Collection;

public class KeyStoreBuilder {
    private static final String keyManagerAlgorithm = KeyManagerFactory.getDefaultAlgorithm();

    // Based on some quick research, this appears to be the default java trust store location
    private static final Path defaultTrustStorePath = Paths.get(System.getProperty("java.home"), "lib", "security", "cacerts");

    // 'changeit' appears to be the default passphrase. I suppose it's ok. Or is it?!!!
    private static final char[] defaultTrustStorePassphrase = "changeit".toCharArray();
    private static final Logger logger = LogManager.getLogger();
    // the "hurray" passphrase is only to satisfy the KeyStore.load API
    // (requires a passphrase, even when loading null).
    private final char[] IN_MEMORY_KEYSTORE_PASSPHRASE = "hurray".toCharArray();
    private boolean modified;
    private KeyStore keyStore;
    private KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(keyManagerAlgorithm);

    public KeyStoreBuilder() {
        empty();
        modified = false;
    }

    /**
     * Start with an empty keystore.
     */
    private void empty() {
        try {
            keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
            keyStore.load(null, IN_MEMORY_KEYSTORE_PASSPHRASE);
            keyManagerFactory.init(keyStore, IN_MEMORY_KEYSTORE_PASSPHRASE);
        } catch (IOException | CertificateException | UnrecoverableKeyException | NoSuchAlgorithmException | KeyStoreException e) {
            throw new Error("Initializing an empty keystore should never fail, but it failed.", e);
        }
        modified = true;
    }

    void useDefaultTrustStore() throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException, UnrecoverableKeyException {
        logger.trace("Using default trust store: {}", defaultTrustStorePath);
        useKeyStore(defaultTrustStorePath.toFile(), defaultTrustStorePassphrase);
        modified = true;
    }

    // XXX: This only supports RSA keys right now.
    public void addPrivateKeyPEM(Path keyPath, Path certificatePath) throws IOException, InvalidKeySpecException, NoSuchAlgorithmException, CertificateException, KeyStoreException, UnrecoverableKeyException {
        PrivateKey key;
        key = KeyStoreUtils.loadPrivateKeyPEM(keyPath);
        Collection<? extends Certificate> certificates;
        certificates = parseCertificatesPath(certificatePath);

        logger.info("Adding key+cert named '{}' to internal keystore.", "mykey");
        keyStore.setKeyEntry("mykey", key, IN_MEMORY_KEYSTORE_PASSPHRASE, certificates.toArray(new Certificate[0]));
        keyManagerFactory.init(keyStore, IN_MEMORY_KEYSTORE_PASSPHRASE);
        modified = true;
    }

    public void addCAPath(Path path) throws CertificateException, IOException, KeyStoreException {
        if (path == null) {
            throw new NullPointerException("path must not be null");
        }

        if (Files.isDirectory(path)) {
            logger.info("Adding all files in {} to trusted certificate authorities.", path);
            for (File file : path.toFile().listFiles()) {
                if (file.isFile()) {
                    addCAPath(file);
                } else {
                    logger.info("Ignoring non-file '{}'", file);
                }
            }
        } else {
            addCAPath(path.toFile());
        }
    }

    void addCAPath(File file) throws CertificateException, IOException, KeyStoreException {
        for (Certificate cert : parseCertificatesPath(file.toPath())) {
            logger.debug("Loaded certificate from {}: {}", file, ((X509Certificate) cert).getSubjectX500Principal());
            String alias = ((X509Certificate) cert).getSubjectX500Principal().toString();
            keyStore.setCertificateEntry(alias, cert);
        }
        modified = true;
    }

    Collection<? extends Certificate> parseCertificatesPath(Path path) throws IOException, CertificateException {
        CertificateFactory cf = CertificateFactory.getInstance("X.509");
        try (FileInputStream in = new FileInputStream(path.toFile())) {
            return cf.generateCertificates(in);
        }
    }

    public void useKeyStore(File path) throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException, UnrecoverableKeyException {
        try {
            useKeyStore(path, defaultTrustStorePassphrase);
        } catch (IOException e) {
            if (e.getCause() instanceof UnrecoverableKeyException) {
                System.out.printf("Enter passphrase for keyStore %s: ", path);
                char[] passphrase = System.console().readPassword();
                useKeyStore(path, passphrase);

                // Make an effort to not keep the passphrase in-memory longer than necessary? Maybe?
                // This may not matter, anyway, since I'm pretty sure KeyManagerFactor.init() keeps it anyway...
                Arrays.fill(passphrase, (char) 0);
            } else {
                throw e;
            }
        }
    }

    void useKeyStore(File path, char[] passphrase) throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException, UnrecoverableKeyException {
        FileInputStream fs;

        fs = new FileInputStream(path);
        keyStore.load(fs, passphrase);
        keyManagerFactory.init(keyStore, passphrase);

        logger.info("Loaded keyStore with {} certificates: {}", (keyStore).size(), path);
        modified = true;
    }

    public KeyStore buildKeyStore() throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException, UnrecoverableKeyException {
        if (!modified) {
            useDefaultTrustStore();
        }
        logger.trace("Returning non-default keystore");
        return keyStore;
    }

    public KeyManagerFactory buildKeyManagerFactory() throws IOException, CertificateException, NoSuchAlgorithmException, KeyStoreException, UnrecoverableKeyException {
        buildKeyStore();
        return keyManagerFactory;
    }


}
