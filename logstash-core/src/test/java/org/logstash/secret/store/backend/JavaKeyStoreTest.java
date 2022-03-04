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


package org.logstash.secret.store.backend;


import org.junit.Before;
import org.junit.Ignore;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.junit.rules.TemporaryFolder;
import org.logstash.secret.SecretIdentifier;
import org.logstash.secret.store.SecretStore;
import org.logstash.secret.store.SecretStoreException;
import org.logstash.secret.store.SecretStoreFactory;
import org.logstash.secret.store.SecureConfig;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.channels.FileLock;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.PosixFileAttributeView;
import java.nio.file.attribute.PosixFilePermission;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static java.nio.file.attribute.PosixFilePermission.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Fail.fail;
import static org.logstash.secret.store.SecretStoreFactory.LOGSTASH_MARKER;

/**
 * Unit tests for the {@link JavaKeyStore}
 */
public class JavaKeyStoreTest {

    private final static String EXTERNAL_TEST_FILE_LOCK = "test_file_lock";
    private final static String EXTERNAL_TEST_WRITE = "test_external_write";
    @Rule
    public TemporaryFolder folder = new TemporaryFolder();
    @Rule
    public ExpectedException thrown = ExpectedException.none();
    private JavaKeyStore keyStore;
    private char[] keyStorePath;
    private SecureConfig withDefaultPassConfig;
    private SecureConfig withDefinedPassConfig;

    /**
     * Launch a second JVM with the expected args
     * <ul>
     * <li>arg[0] - the descriptor to identify which test this is for</li>
     * <li>arg[1] - path to file to write as marker that the second JVM is ready to be tested</li>
     * <li>arg[2..n] - any additional information needed for the test</li>
     * </ul>
     *
     * @param args the args as described
     * @throws IOException when i/o exceptions happen
     */
    public static void main(String... args) throws IOException, InterruptedException {

        Path magicFile = Paths.get(args[1]);

        //Use a second JVM to lock the keystore for 2 seconds
        if (EXTERNAL_TEST_FILE_LOCK.equals(args[0])) {
            Path keystoreFile = Paths.get(args[2]);
            FileLock fileLock = null;
            try (final FileOutputStream keystore = new FileOutputStream(keystoreFile.toFile(), true)) {
                fileLock = keystore.getChannel().tryLock();
                assertThat(fileLock).isNotNull();
                //write the magic file to let the other process know the test is ready
                try (final OutputStream os = Files.newOutputStream(magicFile)) {
                    os.write(args[0].getBytes(StandardCharsets.UTF_8));
                    Thread.sleep(2000);
                } finally {
                    Files.delete(magicFile);
                }
            } finally {
                if (fileLock != null) {
                    fileLock.release();
                }
            }
        } else if (EXTERNAL_TEST_WRITE.equals(args[0])) {
            Path keyStoreFile = Paths.get(args[2]);
            SecureConfig config = new SecureConfig();
            config.add("keystore.file", keyStoreFile.toAbsolutePath().toString().toCharArray());
            JavaKeyStore keyStore = new JavaKeyStore().create(config);
            writeAtoZ(keyStore);
            validateAtoZ(keyStore);
            //write the magic file to let the other process know the test is ready
            try (final OutputStream os = Files.newOutputStream(magicFile)) {
                os.write(args[0].getBytes(StandardCharsets.UTF_8));
            } finally {
                Files.delete(magicFile);
            }
        }
    }

    private static void validateAtoZ(JavaKeyStore keyStore) {
        //contents of the existing is a-z for both the key and value
        for (int i = 65; i <= 90; i++) {
            byte[] expected = new byte[]{(byte) i};
            SecretIdentifier id = new SecretIdentifier(new String(expected, StandardCharsets.UTF_8));
            assertThat(keyStore.retrieveSecret(id)).isEqualTo(expected);
        }
    }

    private static void writeAtoZ(JavaKeyStore keyStore) {
        //a-z key and value
        for (int i = 65; i <= 90; i++) {
            byte[] expected = new byte[]{(byte) i};
            SecretIdentifier id = new SecretIdentifier(new String(expected, StandardCharsets.UTF_8));
            keyStore.persistSecret(id, expected);
        }
    }

    @Before
    public void _setup() throws Exception {
        keyStorePath = folder.newFolder().toPath().resolve("logstash.keystore").toString().toCharArray();
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", keyStorePath.clone());
        keyStore = new JavaKeyStore().create(secureConfig);

        withDefinedPassConfig = new SecureConfig();
        withDefinedPassConfig.add(SecretStoreFactory.KEYSTORE_ACCESS_KEY, "mypassword".toCharArray());
        withDefinedPassConfig.add("keystore.file",
                Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore.with.defined.pass").toURI()).toString().toCharArray());

        withDefaultPassConfig = new SecureConfig();
        withDefaultPassConfig.add("keystore.file",
                Paths.get(this.getClass().getClassLoader().getResource("logstash.keystore.with.default.pass").toURI()).toString().toCharArray());
    }

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

    @Test (expected = SecretStoreException.CreateException.class)
    public void invalidDirectory() throws IOException {
        keyStorePath = Paths.get("/doesnt_exist_root_volume").resolve("logstash.keystore").toString().toCharArray();
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", keyStorePath.clone());
        keyStore = new JavaKeyStore().create(secureConfig);
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
        byte[] marker = keyStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());

        //exiting
        JavaKeyStore existingKeyStore = new JavaKeyStore().load(withDefinedPassConfig);
        marker = existingKeyStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
    }

    /**
     * Tests that trying to read a random file throws the right error.
     *
     * @throws Exception when ever it wants to.
     */
    @Test
    public void notLogstashKeystore() throws Exception {
        thrown.expect(SecretStoreException.class);
        SecureConfig altConfig = new SecureConfig();
        Path altPath = folder.newFolder().toPath().resolve("alt.not.a.logstash.keystore");
        try (OutputStream out = Files.newOutputStream(altPath)) {
            byte[] randomBytes = new byte[300];
            new Random().nextBytes(randomBytes);
            out.write(randomBytes);
        }
        altConfig.add("keystore.file", altPath.toString().toCharArray());
        new JavaKeyStore().load(altConfig);
    }

    /**
     * Tests that when the magic marker that identifies this a logstash keystore is not present the correct exception is thrown.
     *
     * @throws Exception when ever it wants to.
     */
    @Test
    public void notLogstashKeystoreNoMarker() throws Exception {
        thrown.expect(SecretStoreException.LoadException.class);
        withDefinedPassConfig.add("keystore.file", Paths.get(this.getClass().getClassLoader().getResource("not.a.logstash.keystore").toURI()).toString().toCharArray().clone());
        new JavaKeyStore().load(withDefinedPassConfig);
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
        //uses an explicit password
        validateAtoZ(new JavaKeyStore().load(this.withDefinedPassConfig));

        //uses an implicit password
        validateAtoZ(new JavaKeyStore().load(this.withDefaultPassConfig));
    }

    /**
     * Comprehensive tests that uses a freshly created keystore to write 26 entries, list them, read them, and delete them.
     */
    @Test
    public void readWriteListDelete() {
        writeAtoZ(keyStore);
        Collection<SecretIdentifier> foundIds = keyStore.list();
        assertThat(keyStore.list().size()).isEqualTo(26 + 1);
        validateAtoZ(keyStore);
        foundIds.stream().filter(id -> !id.equals(LOGSTASH_MARKER)).forEach(id -> keyStore.purgeSecret(id));
        assertThat(keyStore.list().size()).isEqualTo(1);
        assertThat(keyStore.list().stream().findFirst().get()).isEqualTo(LOGSTASH_MARKER);
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

    /**
     * Test to ensure that keystore is tamper proof.  This really ends up testing the Java's KeyStore implementation, not the code here....but an important attribute to ensure
     * for any type of secret store.
     *
     * @throws Exception when ever it wants to
     */
    @Test
    public void tamperedKeystore() throws Exception {
        thrown.expect(SecretStoreException.class);
        byte[] keyStoreAsBytes = Files.readAllBytes(Paths.get(new String(keyStorePath)));
        //bump the middle byte by 1
        int tamperLocation = keyStoreAsBytes.length / 2;
        keyStoreAsBytes[tamperLocation] = (byte) (keyStoreAsBytes[tamperLocation] + 1);
        Path tamperedPath = folder.newFolder().toPath().resolve("tampered.logstash.keystore");
        Files.write(tamperedPath, keyStoreAsBytes);
        SecureConfig sc = new SecureConfig();
        sc.add("keystore.file", tamperedPath.toString().toCharArray());
        new JavaKeyStore().load(sc);
    }

    /**
     * Ensures correct error when trying to re-create a pre-existing store
     *
     * @throws IOException when it goes boom.
     */
    @Test
    public void testAlreadyCreated() throws IOException {
        thrown.expect(SecretStoreException.AlreadyExistsException.class);
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", keyStorePath.clone());
        new JavaKeyStore().create(secureConfig);
    }

    /**
     * The default permissions should be restrictive for Posix filesystems.
     *
     * @throws Exception when it goes boom.
     */
    @Test
    public void testDefaultPermissions() throws Exception {
        PosixFileAttributeView attrs = Files.getFileAttributeView(Paths.get(new String(keyStorePath)), PosixFileAttributeView.class);

        boolean isWindows = System.getProperty("os.name").startsWith("Windows");
        //not all Windows FS are Posix
        if (!isWindows && attrs == null) {
            fail("Can not determine POSIX file permissions for " + keyStore + " this is likely an error in the test");
        }
        // if we got attributes, lets assert them.
        if (attrs != null) {
            Set<PosixFilePermission> permissions = attrs.readAttributes().permissions();
            EnumSet<PosixFilePermission> expected = EnumSet.of(OWNER_READ, OWNER_WRITE, GROUP_READ, OTHERS_READ);
            assertThat(permissions.toArray()).containsExactlyInAnyOrder(expected.toArray());
        }
    }

    @Test
    public void testDelete() throws IOException {
        thrown.expect(SecretStoreException.LoadException.class);
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig altConfig = new SecureConfig();
        altConfig.add("keystore.file", altPath.toString().toCharArray());
        SecretStore secretStore = new JavaKeyStore().create(altConfig.clone());
        assertThat(secretStore.exists(altConfig.clone())).isTrue();
        byte[] marker = keyStore.retrieveSecret(LOGSTASH_MARKER);
        assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
        secretStore.delete(altConfig.clone());
        assertThat(secretStore.exists(altConfig.clone())).isFalse();
       new JavaKeyStore().load(altConfig.clone());

    }

    /**
     * Empty passwords are not allowed
     *
     * @throws IOException when ever it wants to
     */
    @Test
    public void testEmptyNotAllowedOnCreate() throws IOException {
        thrown.expect(SecretStoreException.CreateException.class);
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig altConfig = new SecureConfig();
        altConfig.add("keystore.file", altPath.toString().toCharArray());
        altConfig.add(SecretStoreFactory.KEYSTORE_ACCESS_KEY, "".toCharArray());
        new JavaKeyStore().create(altConfig);
    }

    /**
     * Empty passwords should always throw an Access Exception
     *
     * @throws Exception when ever it wants to
     */
    @Test
    public void testEmptyNotAllowedOnExisting() throws Exception {
        thrown.expect(SecretStoreException.AccessException.class);
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig altConfig = new SecureConfig();
        altConfig.add("keystore.file", altPath.toString().toCharArray());
        SecureConfig altConfig2 = altConfig.clone();
        altConfig2.add("keystore.file", altPath.toString().toCharArray());
        altConfig2.add(SecretStoreFactory.KEYSTORE_ACCESS_KEY, "".toCharArray());
        new JavaKeyStore().create(altConfig);
        new JavaKeyStore().load(altConfig2);
    }

    /**
     * Simulates different JVMs modifying the keystore and ensure a consistent list view
     *
     * @throws IOException when it goes boom.
     */
    @Test
    public void testExternalUpdateList() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", altPath.toString().toCharArray());
        JavaKeyStore keyStore1 = new JavaKeyStore().create(secureConfig.clone());
        JavaKeyStore keyStore2 = new JavaKeyStore().load(secureConfig);
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
     * Simulates different JVMs modifying the keystore and ensure a consistent view
     *
     * @throws IOException when it goes boom.
     */
    @Test
    public void testExternalUpdatePersist() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", altPath.toString().toCharArray());
        JavaKeyStore keyStore1 = new JavaKeyStore().create(secureConfig.clone());
        JavaKeyStore keyStore2 = new JavaKeyStore().load(secureConfig);
        String value1 = UUID.randomUUID().toString();
        String value2 = UUID.randomUUID().toString();
        SecretIdentifier id1 = new SecretIdentifier(value1);
        SecretIdentifier id2 = new SecretIdentifier(value2);
        //jvm1 persist id1, jvm2 persist id2
        keyStore1.persistSecret(id1, value1.getBytes(StandardCharsets.UTF_8));
        keyStore2.persistSecret(id2, value2.getBytes(StandardCharsets.UTF_8));
        //both keystores should contain both values
        assertThat(keyStore1.list().stream().map(k -> keyStore1.retrieveSecret(k)).map(v -> new String(v, StandardCharsets.UTF_8))
                .collect(Collectors.toSet())).contains(value1, value2);
        assertThat(keyStore2.list().stream().map(k -> keyStore2.retrieveSecret(k)).map(v -> new String(v, StandardCharsets.UTF_8))
                .collect(Collectors.toSet())).contains(value1, value2);
        //purge from jvm1
        keyStore1.purgeSecret(id1);
        keyStore1.purgeSecret(id2);
        assertThat(keyStore1.retrieveSecret(new SecretIdentifier(value1))).isNull();
        assertThat(keyStore1.retrieveSecret(new SecretIdentifier(value2))).isNull();
        assertThat(keyStore2.retrieveSecret(new SecretIdentifier(value1))).isNull();
        assertThat(keyStore2.retrieveSecret(new SecretIdentifier(value2))).isNull();
    }

    /**
     * Simulates different JVMs modifying the keystore and ensure a consistent read view
     *
     * @throws IOException when it goes boom.
     */
    @Test
    public void testExternalUpdateRead() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", altPath.toString().toCharArray());
        secureConfig.add(SecretStoreFactory.KEYSTORE_ACCESS_KEY, "mypass".toCharArray());
        JavaKeyStore keyStore1 = new JavaKeyStore().create(secureConfig.clone());
        JavaKeyStore keyStore2 = new JavaKeyStore().load(secureConfig);
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
     * Spins up a second VM, locks the underlying keystore, asserts correct exception, once lock is released and now can write
     *
     * @throws Exception when exceptions happen
     */
    @Test
    public void testFileLock() throws Exception {
        boolean isWindows = System.getProperty("os.name").startsWith("Windows");
        Path magicFile = folder.newFolder().toPath().resolve(EXTERNAL_TEST_FILE_LOCK);

        String java = System.getProperty("java.home") + File.separator + "bin" + File.separator + "java";
        ProcessBuilder builder = new ProcessBuilder(java, "-cp", System.getProperty("java.class.path"), getClass().getCanonicalName(),
                EXTERNAL_TEST_FILE_LOCK, magicFile.toAbsolutePath().toString(), new String(keyStorePath));
        Future<Integer> future = Executors.newScheduledThreadPool(1).submit(() -> builder.start().waitFor());

        boolean passed = false;
        while (!future.isDone()) {
            try {
                Files.readAllBytes(magicFile);
            } catch (NoSuchFileException sfe) {
                Thread.sleep(100);
                continue;
            }
            try {
                keyStore.persistSecret(new SecretIdentifier("foo"), "bar".getBytes(StandardCharsets.UTF_8));
            } catch (SecretStoreException.PersistException e) {
                assertThat(e.getCause().getMessage()).contains("locked");
                passed = true;
            }
            break;
        }
        assertThat(passed).isTrue();

        // The keystore.store method on Windows checks for the file lock and does not allow _any_ interaction with the keystore if it is locked.
        if (!isWindows) {
            //can still read
            byte[] marker = keyStore.retrieveSecret(LOGSTASH_MARKER);
            assertThat(new String(marker, StandardCharsets.UTF_8)).isEqualTo(LOGSTASH_MARKER.getKey());
        }

        //block until other JVM finishes
        future.get();
        //can write/read now
        SecretIdentifier id = new SecretIdentifier("foo2");
        keyStore.persistSecret(id, "bar".getBytes(StandardCharsets.UTF_8));
        assertThat(new String(keyStore.retrieveSecret(id), StandardCharsets.UTF_8)).isEqualTo("bar");
    }

    /**
     * Simulates different JVMs can read using a default (non-provided) password
     *
     * @throws IOException when it goes boom.
     */
    @Test
    public void testGeneratedSecret() throws IOException {
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig altConfig = new SecureConfig();
        altConfig.add("keystore.file", altPath.toString().toCharArray());
        //note - no password given here.
        JavaKeyStore keyStore1 = new JavaKeyStore().create(altConfig.clone());
        JavaKeyStore keyStore2 = new JavaKeyStore().load(altConfig);
        String value = UUID.randomUUID().toString();
        SecretIdentifier id = new SecretIdentifier(value);
        //jvm1 persist, jvm2 read
        keyStore1.persistSecret(id, value.getBytes(StandardCharsets.UTF_8));
        assertThat(new String(keyStore2.retrieveSecret(new SecretIdentifier(value)), StandardCharsets.UTF_8)).isEqualTo(value);
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

    @Test
    public void testLoadNotCreated() throws IOException {
        thrown.expect(SecretStoreException.LoadException.class);
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
        SecureConfig secureConfig = new SecureConfig();
        secureConfig.add("keystore.file", altPath.toString().toCharArray());
        new JavaKeyStore().load(secureConfig.clone());
    }

    @Test
    public void testNoPathDefined() {
        thrown.expect(SecretStoreException.LoadException.class);
        new JavaKeyStore().load(new SecureConfig());
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

        SecureConfig sc = new SecureConfig();
        sc.add(SecretStoreFactory.KEYSTORE_ACCESS_KEY, nonAscii.toCharArray());
        sc.add("keystore.file", (new String(keyStorePath) + ".nonAscii").toCharArray());
        JavaKeyStore nonAsciiKeyStore = new JavaKeyStore().create(sc);

        SecretIdentifier id = new SecretIdentifier(nonAscii);
        nonAsciiKeyStore.persistSecret(id, nonAscii.getBytes(StandardCharsets.UTF_8));
        assertThat(new String(nonAsciiKeyStore.retrieveSecret(id), StandardCharsets.UTF_8)).isEqualTo(nonAscii);
    }

    /**
     * Ensure the permissions can be set to be set more restrictive then default
     *
     * @throws Exception when it goes boom.
     */
    @Test
    public void testRestrictivePermissions() throws Exception {
        String beforeTest = JavaKeyStore.filePermissions;
        JavaKeyStore.filePermissions = "rw-------";
        try {
            Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");
            SecureConfig secureConfig = new SecureConfig();
            secureConfig.add("keystore.file", altPath.toString().toCharArray());

            keyStore = new JavaKeyStore().create(secureConfig);
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
            JavaKeyStore.filePermissions = beforeTest;
        }
    }

    /**
     * Spins up a second JVM, writes all the data, then read it from this JVM
     *
     * @throws Exception when exceptions happen
     */
    @Ignore("This test timed out on Windows. Issue: https://github.com/elastic/logstash/issues/9916")
    @Test
    public void testWithRealSecondJvm() throws Exception {
        Path magicFile = folder.newFolder().toPath().resolve(EXTERNAL_TEST_FILE_LOCK);
        Path altPath = folder.newFolder().toPath().resolve("alt.logstash.keystore");

        String java = System.getProperty("java.home") + File.separator + "bin" + File.separator + "java";
        ProcessBuilder builder = new ProcessBuilder(java, "-cp", System.getProperty("java.class.path"), getClass().getCanonicalName(),
                EXTERNAL_TEST_WRITE, magicFile.toAbsolutePath().toString(), altPath.toAbsolutePath().toString());
        Future<Integer> future = Executors.newScheduledThreadPool(1).submit(() -> builder.start().waitFor());

        while (!future.isDone()) {
            try {
                Files.readAllBytes(magicFile);
            } catch (NoSuchFileException sfe) {
                Thread.sleep(100);
                continue;
            }
        }
        SecureConfig config = new SecureConfig();
        config.add("keystore.file", altPath.toAbsolutePath().toString().toCharArray());
        JavaKeyStore keyStore = new JavaKeyStore().load(config);
        validateAtoZ(keyStore);
    }

    /**
     * Ensure that the when the wrong password is presented the corrected exception is thrown.
     *
     * @throws Exception when ever it wants to
     */
    @Test
    public void wrongPassword() throws Exception {
        thrown.expect(SecretStoreException.AccessException.class);
        withDefinedPassConfig.add(SecretStoreFactory.KEYSTORE_ACCESS_KEY, "wrongpassword".toCharArray());
        new JavaKeyStore().load(withDefinedPassConfig);
    }

    @Test(timeout = 40_000)
    public void concurrentReadTest() throws Exception {

        final int KEYSTORE_COUNT = 250;

        final ExecutorService executorService = Executors.newFixedThreadPool(KEYSTORE_COUNT);
        String password = "pAssW3rd!";
        keyStore.persistSecret(new SecretIdentifier("password"), password.getBytes(StandardCharsets.UTF_8));
        try{
            Callable<byte[]> reader = () -> keyStore.retrieveSecret(new SecretIdentifier("password"));

            List<Future<byte[]>> futures = new ArrayList<>();
            for (int i = 0; i < KEYSTORE_COUNT; i++) {
                futures.add(executorService.submit(reader));
            }

            for (Future<byte[]> future : futures) {
                byte[] result = future.get();
                assertThat(result).isNotNull();
                assertThat(new String(result, StandardCharsets.UTF_8)).isEqualTo(password);
            }
        } finally {
            executorService.shutdownNow();
            executorService.awaitTermination(Long.MAX_VALUE, TimeUnit.MILLISECONDS);
        }
    }
}