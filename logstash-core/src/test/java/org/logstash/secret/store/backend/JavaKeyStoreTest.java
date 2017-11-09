package org.logstash.secret.store.backend;


import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.junit.rules.TemporaryFolder;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.SecretStoreException;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.PosixFileAttributeView;
import java.nio.file.attribute.PosixFilePermission;
import java.util.*;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static java.nio.file.attribute.PosixFilePermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Fail.fail;
import static org.hamcrest.CoreMatchers.instanceOf;

/**
 * Unit tests for the {@link JavaKeyStore}
 */
public class JavaKeyStoreTest {

    @Rule
    public TemporaryFolder folder = new TemporaryFolder();

    @Rule
    public ExpectedException thrown = ExpectedException.none();
    private JavaKeyStore keyStore;
    private char[] keyStorePass;
    private Path keyStorePath;

    /**
     * Simple example usage.
     */
    @Test
    public void basicTest() {
        String password = "pAssW3rd!";
        //persist
        keyStore.persistSecret(new SecretIdentifier("mysql.password"), password.getBytes(StandardCharsets.UTF_8));
        //retrieve
        byte[] secret = keyStore.retrieveSecret(new SecretIdentifier("mysql.password"));
        assertThat(new String(secret, StandardCharsets.UTF_8)).isEqualTo(password);
        //purge
        keyStore.purgeSecret(new SecretIdentifier("mysql.password"));
        secret = keyStore.retrieveSecret(new SecretIdentifier("mysql.password"));
        assertThat(secret).isNull();
    }

    /**
     * Tests that the magic marker that identifies this a logstash keystore is present.  This marker helps to ensure that we are only dealing with our keystore, we do not want
     * to support arbitrary keystores.
     *
     * @throws Exception when ever it wants to.
     */
    @Test
    public void isLogstashKeystore() throws Exception {
        //newly created
        byte[] marker = keyStore.retrieveSecret(new SecretIdentifier(JavaKeyStore.LOGSTASH_MARKER));
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(JavaKeyStore.LOGSTASH_MARKER);

        //exiting
        JavaKeyStore existingKeyStore = new JavaKeyStore(Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore").toURI()), "mypassword".toCharArray());
        marker = existingKeyStore.retrieveSecret(new SecretIdentifier(JavaKeyStore.LOGSTASH_MARKER));
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(JavaKeyStore.LOGSTASH_MARKER);
    }

    /**
     * Tests that when the magic marker that identifies this a logstash keystore is not present the correct exception is thrown.
     *
     * @throws Exception when ever it wants to.
     */
    @Test
    public void notLogstashKeystore() throws Exception {
        thrown.expect(SecretStoreException.NotLogstashKeyStore.class);
        new JavaKeyStore(Paths.get(this.getClass().getClassLoader().getResource("not.a.logstash.keystore").toURI()), "mypassword".toCharArray());
    }

    /**
     * Overwrite should be no-error overwrite
     */
    @Test
    public void overwriteExisting() {
        SecretIdentifier id = new SecretIdentifier("myId");
        int originalSize = keyStore.list().size();

        keyStore.persistSecret(id, "password1".getBytes(StandardCharsets.UTF_8));
        assertThat(keyStore.list().size()).isEqualTo(originalSize + 1);
        assertThat(new String(keyStore.retrieveSecret(id), StandardCharsets.UTF_8)).isEqualTo("password1");

        keyStore.persistSecret(id, "password2".getBytes(StandardCharsets.UTF_8));
        assertThat(keyStore.list().size()).isEqualTo(originalSize + 1);
        assertThat(new String(keyStore.retrieveSecret(id), StandardCharsets.UTF_8)).isEqualTo("password2");
    }

    /**
     * Purging missing secrets should be no-error no-op
     */
    @Test
    public void purgeMissingSecret() {
        Collection<SecretIdentifier> original = keyStore.list();
        keyStore.purgeSecret(new SecretIdentifier("does-not-exist"));
        assertThat(keyStore.list().toArray()).containsExactlyInAnyOrder(original.toArray());
    }

    /**
     * Tests that we can read a pre-existing keystore from disk.
     *
     * @throws Exception when ever it wants to.
     */
    @Test
    public void readExisting() throws Exception {
        JavaKeyStore existingKeyStore = new JavaKeyStore(Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore").toURI()), "mypassword".toCharArray());
        //contents of the existing is a-z for both the key and value
        for (int i = 65; i <= 90; i++) {
            byte[] expected = new byte[]{(byte) i};
            SecretIdentifier id = new SecretIdentifier(new String(expected, StandardCharsets.UTF_8));
            assertThat(existingKeyStore.retrieveSecret(id)).isEqualTo(expected);
        }
    }

    /**
     * Comprehensive tests that uses a freshly created keystore to write 26 entries, list them, read them, and delete them.
     */
    @Test
    public void readWriteListDelete() {
        Set<String> values = new HashSet<>(27);
        Set<SecretIdentifier> keys = new HashSet<>(27);
        SecretIdentifier markerId = new SecretIdentifier(JavaKeyStore.LOGSTASH_MARKER);
        //add the marker
        keys.add(markerId);
        values.add(JavaKeyStore.LOGSTASH_MARKER);
        //a-z key and value
        for (int i = 65; i <= 90; i++) {
            byte[] expected = new byte[]{(byte) i};
            values.add(new String(expected, StandardCharsets.UTF_8));
            SecretIdentifier id = new SecretIdentifier(new String(expected, StandardCharsets.UTF_8));
            keyStore.persistSecret(id, expected);
            keys.add(id);
        }
        Collection<SecretIdentifier> foundIds = keyStore.list();
        assertThat(keyStore.list().size()).isEqualTo(26 + 1);
        assertThat(values.size()).isEqualTo(26 + 1);
        assertThat(keys.size()).isEqualTo(26 + 1);

        foundIds.stream().forEach(id -> assertThat(keys).contains(id));
        foundIds.stream().forEach(id -> assertThat(values).contains(new String(keyStore.retrieveSecret(id), StandardCharsets.UTF_8)));

        foundIds.stream().filter(id -> !id.equals(markerId)).forEach(id -> keyStore.purgeSecret(id));

        assertThat(keyStore.list().size()).isEqualTo(1);
        assertThat(keyStore.list().stream().findFirst().get()).isEqualTo(markerId);
    }

    /**
     * Retrieving missing should be no-error, null result
     */
    @Test
    public void retrieveMissingSecret() {
        assertThat(keyStore.retrieveSecret(new SecretIdentifier("does-not-exist"))).isNull();
    }

    /**
     * Invalid input should be no-error, null result
     */
    @Test
    public void retrieveWithInvalidInput() {
        assertThat(keyStore.retrieveSecret(null)).isNull();
    }

    @Before
    public void setup() throws Exception {
        keyStorePath = folder.newFolder().toPath().resolve("logstash.keystore");
        keyStorePass = UUID.randomUUID().toString().toCharArray();
        keyStore = new JavaKeyStore(keyStorePath, keyStorePass);
    }

    /**
     * Test to ensure that keystore is tamper proof.  This really ends up testing the Java's KeyStore implementation, not the code here....but an important attribute to ensure
     * for any type of secret store.
     *
     * @throws Exception when ever it wants to
     */
    @Test
    public void tamperedKeystore() throws Exception {

        thrown.expect(SecretStoreException.NotLogstashKeyStore.class);
        byte[] keyStoreAsBytes = Files.readAllBytes(keyStorePath);
        //bump the middle byte by 1
        int tamperLocation = keyStoreAsBytes.length / 2;
        keyStoreAsBytes[tamperLocation] = (byte) (keyStoreAsBytes[tamperLocation] + 1);
        Path tamperedPath = folder.newFolder().toPath().resolve("tampered.logstash.keystore");
        Files.write(tamperedPath, keyStoreAsBytes);
        new JavaKeyStore(tamperedPath, keyStorePass);
    }

    /**
     * Test upper sane bounds.
     */
    @Test
    public void testLargeKeysAndValues() {
        int keySize = 1000;
        int valueSize = 100000;
        StringBuilder keyBuilder = new StringBuilder(keySize);
        IntStream.range(0, keySize).forEach(i -> keyBuilder.append('k'));
        String key = keyBuilder.toString();

        StringBuilder valueBuilder = new StringBuilder(valueSize);
        IntStream.range(0, valueSize).forEach(i -> valueBuilder.append('v'));
        String value = valueBuilder.toString();

        SecretIdentifier id = new SecretIdentifier(key);
        keyStore.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));

        byte[] secret = keyStore.retrieveSecret(id);
        assertThat(new String(secret, StandardCharsets.UTF_8)).isEqualTo(value);

        keyStore.purgeSecret(id);
    }

    /**
     * Ensure that non-ascii keys and values are properly handled.
     *
     * @throws Exception when the clowns cry
     */
    @Test
    public void testNonAscii() throws Exception {
        int[] codepoints = {0xD83E, 0xDD21, 0xD83E, 0xDD84};
        String nonAscii = new String(codepoints, 0, codepoints.length);
        SecretIdentifier id = new SecretIdentifier(nonAscii);
        keyStore.persistSecret(id, nonAscii.getBytes(StandardCharsets.UTF_8));
        assertThat(new String(keyStore.retrieveSecret(id), StandardCharsets.UTF_8)).isEqualTo(nonAscii);
    }

    /**
     * The default permissions should be restrictive for Posix filesystems.
     *
     * @throws Exception when it goes boom.
     */
    @Test
    public void testDefaultPermissions() throws Exception {
        PosixFileAttributeView attrs = Files.getFileAttributeView(keyStorePath, PosixFileAttributeView.class);
        boolean isWindows = System.getProperty("os.name").startsWith("Windows");
        //not all Windows FS are Posix
        if (!isWindows && attrs == null) {
            fail("Can not determine POSIX file permissions for " + keyStore + " this is likely an error in the test");
        }
        // if we got attributes, lets assert them.
        if (attrs != null) {
            Set<PosixFilePermission> permissions = attrs.readAttributes().permissions();
            EnumSet<PosixFilePermission> expected = EnumSet.of(OWNER_READ, OWNER_WRITE, GROUP_READ, GROUP_WRITE);
            assertThat(permissions.toArray()).containsExactlyInAnyOrder(expected.toArray());
        }
    }

    /**
     * Ensure the permissions can be set to be set more restrictive then default
     *
     * @throws Exception when it goes boom.
     */
    @Test
    public void testRestrictivePermissions() throws Exception {
        String beforeTest = System.getProperty("logstash.keystore.file.perms");
        try {
            System.setProperty("logstash.keystore.file.perms", "rw-------");
            Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
            keyStore = new JavaKeyStore(altPath, keyStorePass);
            assertThat(altPath.toFile().exists()).isTrue();
            PosixFileAttributeView attrs = Files.getFileAttributeView(altPath, PosixFileAttributeView.class);

            boolean isWindows = System.getProperty("os.name").startsWith("Windows");
            //not all Windows FS are Posix
            if (!isWindows && attrs == null) {
                fail("Can not determine POSIX file permissions for " + keyStore + " this is likely an error in the test");
            }
            // if we got attributes, lets assert them.
            if (attrs != null) {
                Set<PosixFilePermission> permissions = attrs.readAttributes().permissions();
                EnumSet<PosixFilePermission> expected = EnumSet.of(OWNER_READ, OWNER_WRITE);
                assertThat(permissions.toArray()).containsExactlyInAnyOrder(expected.toArray());
            }
        } finally {
            if (beforeTest == null) {
                System.clearProperty("logstash.keystore.file.perms");
            } else {
                System.setProperty("logstash.keystore.file.perms", beforeTest);
            }
        }
    }

    /**
     * Simulates a different JVM modifying the keystore and ensure a consistent read view
     */
    @Test
    public void testExternalUpdateRead() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        JavaKeyStore keyStore1 = new JavaKeyStore(altPath, "mypass".toCharArray());
        JavaKeyStore keyStore2 = new JavaKeyStore(altPath, "mypass".toCharArray());
        String value = UUID.randomUUID().toString();
        SecretIdentifier id = new SecretIdentifier(value);
        //jvm1 persist, jvm2 read
        keyStore1.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        assertThat(new String(keyStore2.retrieveSecret(new SecretIdentifier(value)), StandardCharsets.UTF_8)).isEqualTo(value);
        //purge from jvm2
        assertThat(new String(keyStore1.retrieveSecret(new SecretIdentifier(value)), StandardCharsets.UTF_8)).isEqualTo(value);
        keyStore2.purgeSecret(id);
        assertThat(keyStore1.retrieveSecret(new SecretIdentifier(value))).isNull();
    }

    /**
     * Simulates a different JVM modifying the keystore and ensure a consistent list view
     */
    @Test
    public void testExternalUpdateList() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        JavaKeyStore keyStore1 = new JavaKeyStore(altPath, "mypass".toCharArray());
        JavaKeyStore keyStore2 = new JavaKeyStore(altPath, "mypass".toCharArray());
        String value = UUID.randomUUID().toString();
        SecretIdentifier id = new SecretIdentifier(value);
        //jvm1 persist, jvm2 list
        keyStore1.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        assertThat(keyStore2.list().stream().map(k -> keyStore2.retrieveSecret(k)).map(v -> new String(v, StandardCharsets.UTF_8)).collect(Collectors.toSet())).contains(value);
        //purge from jvm1
        assertThat(new String(keyStore2.retrieveSecret(new SecretIdentifier(value)), StandardCharsets.UTF_8)).isEqualTo(value);
        keyStore1.purgeSecret(id);
        assertThat(keyStore2.retrieveSecret(new SecretIdentifier(value))).isNull();
    }

    /**
     * Simulates a different JVMs modifying the keystore and ensure a consistent view
     */
    @Test
    public void testExternalUpdatePersist() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        JavaKeyStore keyStore1 = new JavaKeyStore(altPath, "mypass".toCharArray());
        JavaKeyStore keyStore2 = new JavaKeyStore(altPath, "mypass".toCharArray());
        String value1 = UUID.randomUUID().toString();
        String value2 = UUID.randomUUID().toString();
        SecretIdentifier id1 = new SecretIdentifier(value1);
        SecretIdentifier id2 = new SecretIdentifier(value2);
        //jvm1 persist id1, jvm2 persist id2
        keyStore1.persistSecret(id1, value1.getBytes(StandardCharsets.UTF_8));
        keyStore2.persistSecret(id2, value2.getBytes(StandardCharsets.UTF_8));
        //both keystores should contain both values
        assertThat(keyStore1.list().stream().map(k -> keyStore1.retrieveSecret(k)).map(v -> new String(v, StandardCharsets.UTF_8))
                .collect(Collectors.toSet())).contains(value1,  value2);
        assertThat(keyStore2.list().stream().map(k -> keyStore2.retrieveSecret(k)).map(v -> new String(v, StandardCharsets.UTF_8))
                .collect(Collectors.toSet())).contains(value1,  value2);
        //purge from jvm1
        keyStore1.purgeSecret(id1);
        keyStore1.purgeSecret(id2);
        assertThat(keyStore1.retrieveSecret(new SecretIdentifier(value1))).isNull();
        assertThat(keyStore1.retrieveSecret(new SecretIdentifier(value2))).isNull();
        assertThat(keyStore2.retrieveSecret(new SecretIdentifier(value1))).isNull();
        assertThat(keyStore2.retrieveSecret(new SecretIdentifier(value2))).isNull();
    }

    /**
     * Ensure that the when the wrong password is presented the corrected exception is thrown.
     *
     * @throws Exception when ever it wants to
     */
    @Test
    public void wrongPassword() throws Exception {
        thrown.expect(SecretStoreException.AccessException.class);
        new JavaKeyStore(Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore").toURI()), "wrongpassword".toCharArray());
    }
}