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

package org.logstash.settings;

import org.awaitility.Awaitility;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.StandardProtocolFamily;
import java.net.UnixDomainSocketAddress;
import java.nio.channels.ServerSocketChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.FileAttribute;
import java.nio.file.attribute.PosixFilePermission;
import java.nio.file.attribute.PosixFilePermissions;
import java.time.Duration;
import java.util.Set;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.junit.Assume.assumeTrue;

public class WritableDirectorySettingTest {

    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();

    private WritableDirectorySetting sut;

    @Before
    public void setUp() {
        sut = new WritableDirectorySetting("test.path", "", false);
    }

    // ========== validateValue() tests for existing directories ==========

    @Test
    public void whenDirectoryExistsAndIsWritableThenValidationPasses() throws IOException {
        Path existingDir = tempFolder.newFolder("existing").toPath();

        sut.set(existingDir.toString());

        // Should not throw
        sut.validateValue();
    }

    @Test
    public void whenDirectoryExistsButNotWritableThenValidationFails() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(isNotWindowsOS());
        assertFalse("Cannot run as root because root can write to read-only files", isRoot());

        Path existingDir = tempFolder.newFolder("readonly").toPath();
        File dirFile = existingDir.toFile();
        assertTrue("Could not set directory to read-only", dirFile.setWritable(false));
        Awaitility.await("Until the directory is not read-only").until(() -> !dirFile.canWrite());

        sut.set(existingDir.toString());

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("must be a writable directory"));
        assertThat(ex.getMessage(), containsString("It is not writable"));
    }

    private boolean isRoot() {
        boolean isRoot = false;
        try {
            Process p = new ProcessBuilder("id", "-u").start();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(p.getInputStream()))) {
                String uid = reader.readLine();
                isRoot = "0".equals(uid);
            }
        } catch (IOException e) {
            // Not Unix or command failed
        }
        return isRoot;
    }

    @Test
    public void whenDirectoryIsRelativeThenValidationPasses() {
        // Should not throw
        sut.validate("../data");
    }

    @Test
    public void whenDirectoryIsSingleSegmentThenValidationPasses() {
        // Should not throw
        sut.validate("data");
    }

    // ========== validate() tests for existing paths ==========

    @Test
    public void whenPathExistsButIsFileThenValidateFails() throws IOException {
        Path filePath = tempFolder.newFile("afile.txt").toPath();

        // Test validate() directly for specific validation error
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> sut.validate(filePath.toString()));
        assertThat(ex.getMessage(), containsString("must be a writable directory"));
        assertThat(ex.getMessage(), containsString("It is not a directory"));
    }

    // really similar to whenPathExistsButIsFileThenValidateFails
    @Test
    public void whenPathExistsButIsFileThenValidateValueFails() throws IOException {
        Path filePath = tempFolder.newFile("afile.txt").toPath();

        sut.set(filePath.toString());

        // validateValue() calls value() first which tries to create directory at file path
        // This fails with FileAlreadyExistsException wrapped in IllegalArgumentException
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("does not exist and directory creation failed"));
    }

    @Test
    public void whenPathIsSymlinkToNonExistentTargetThenValidationFails() throws IOException {
        // Skip on Windows where symlinks require special permissions
        assumeTrue(isNotWindowsOS());

        // Create symlink to non-existent target (like Ruby test does with "whatever")
        Path symlink = tempFolder.getRoot().toPath().resolve("symlink");
        Files.createSymbolicLink(symlink, tempFolder.getRoot().toPath().resolve("nonexistent"));

        // Test validate() directly for specific validation error
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> sut.validate(symlink.toString()));
        assertThat(ex.getMessage(), containsString("must be a writable directory"));
        assertThat(ex.getMessage(), containsString("cannot be a symlink"));
    }

    @Test
    public void whenPathIsSymlinkToExistingDirectoryThenValidationPasses() throws IOException {
        // Skip on Windows where symlinks require special permissions
        assumeTrue(isNotWindowsOS());

        // Symlink to existing directory - Files.isDirectory() follows symlinks
        // so this is treated as a valid directory (matching Ruby behavior where
        // File.directory? also follows symlinks)
        Path targetDir = tempFolder.newFolder("target").toPath();
        Path symlink = tempFolder.getRoot().toPath().resolve("symlink");
        Files.createSymbolicLink(symlink, targetDir);

        // Should not throw - symlink to writable directory is accepted
        sut.validate(symlink.toString());
    }

    // ========== validate() tests for missing directories ==========

    @Test
    public void whenDirectoryMissingButCanBeCreatedThenValidationPasses() throws IOException {
        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("missing");

        // Ensure it doesn't exist yet
        assertFalse(Files.exists(missingDir));

        sut.set(missingDir.toString());

        // Should not throw - validation passes because parent is writable
        sut.validateValue();
    }

    @Test
    public void whenDirectoryMissingAndParentNotWritableThenValidateFails() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(isNotWindowsOS());
        assertFalse("Can't run as root since root can write anywhere no real read-only files", isRoot());

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("missing");
        File parentFile = parentDir.toFile();
        assertTrue("Could not set parent directory to read-only", parentFile.setWritable(false));
        Awaitility.await("Until the parent directory is not read-only").until(() -> !parentFile.canWrite());

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> sut.validate(missingDir.toString()));
        assertThat(ex.getMessage(), containsString("does not exist and cannot create it"));
        assertThat(ex.getMessage(), containsString("parent path"));
        assertThat(ex.getMessage(), containsString("is not writable"));
    }

    @Test
    public void whenDirectoryMissingAndParentNotWritableThenValidateValueFails() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(isNotWindowsOS());
        assertFalse("Can't run as root since root can write anywhere (no real read-only files)", isRoot());

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("missing");
        File parentFile = parentDir.toFile();
        assertTrue("Could not set parent directory to read-only", parentFile.setWritable(false));
        Awaitility.await("Until the parent directory is not read-only").timeout(Duration.ofMinutes(1)).until(() -> !parentFile.canWrite());

        sut.set(missingDir.toString());

        // validateValue() calls value() first which tries to create directory
        // and fails because parent is not writable
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("does not exist and directory creation failed"));
    }

    // ========== validateValue() tests for null and empty ==========

    @Test
    public void whenPathIsNullThenValidationFails() {
        sut.set(null);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("must be a non-empty String path"));
    }

    @Test
    public void whenPathIsEmptyThenValidationFails() {
        sut.set("");

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("Path \"\" does not exist and directory creation failed"));
    }

    // ========== value() tests ==========

    @Test
    public void givenEmptyPathThenValueFails() {
        sut.set("");

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::value);
        assertThat(ex.getMessage(), containsString("Path \"\" does not exist and directory creation failed"));
    }

    @Test
    public void givenDirectoryMissingAndParentIsWritableThenValueInvocationCreatesDirectory() throws IOException {
        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("newdir");

        assertFalse("missing dir shouldn't exist", Files.exists(missingDir));

        sut.set(missingDir.toString());

        // Calling value() should create the directory
        String result = sut.value();

        assertEquals(missingDir.toString(), result);
        assertTrue("Directory should have been created", Files.isDirectory(missingDir));
    }

    @Test
    public void givenDirectoryMissingAndDirectoryCantBeCreatedThenValueInvocationThrowsError() throws IOException {
        assumeTrue(isNotWindowsOS());
        assertFalse("Can't run as root since root can write anywhere (no real read-only files)", isRoot());

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("newdir");

        assertFalse("missing dir shouldn't exist", Files.exists(missingDir));

        sut.set(missingDir.toString());

        // Make read-only to prevent directory creation
        createAndMakeItReadOnly(missingDir);

        assertThrows(IllegalArgumentException.class, sut::value);
    }

    private static void createAndMakeItReadOnly(Path missingDir) throws IOException {
        File missingFile = missingDir.toFile();
        Set<PosixFilePermission> ownerWritable = PosixFilePermissions.fromString("r--r--r--");
        FileAttribute<?> permissions = PosixFilePermissions.asFileAttribute(ownerWritable);
        Files.createFile(missingDir, permissions);
        Awaitility.await("until the file is created in read-only mode").until(() -> !missingFile.canWrite());
    }

    @Test
    public void whenDirectoryAlreadyExistsThenValueReturnsPath() throws IOException {
        Path existingDir = tempFolder.newFolder("existing").toPath();

        sut.set(existingDir.toString());

        String result = sut.value();

        assertEquals(existingDir.toString(), result);
        assertTrue(Files.isDirectory(existingDir));
    }

    @Test
    public void whenDirectoryCannotBeCreatedThenValueThrows() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(isNotWindowsOS());
        assertFalse("Cannot run as root because root can write to read-only files", isRoot());

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("newdir");
        File parentFile = parentDir.toFile();

        // First set the value, then make parent read-only
        sut.set(missingDir.toString());

        assertTrue("Could not set parent directory to read-only", parentFile.setWritable(false));
        Awaitility.await("Until the parent directory is not read-only").until(() -> !parentFile.canWrite());

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::value);
        assertThat(ex.getMessage(), containsString("does not exist and directory creation failed"));
    }

    // ========== Constructor tests ==========

    @Test
    public void whenStrictModeWithValidDefaultThenConstructorSucceeds() throws IOException {
        Path existingDir = tempFolder.newFolder("valid").toPath();

        // Should not throw - default value is valid
        sut = new WritableDirectorySetting("test.path", existingDir.toString(), true);

        assertEquals(existingDir.toString(), sut.getDefault());
    }

    @Test
    public void whenStrictModeWithInvalidDefaultThenConstructorThrows() {
        // Use a path that doesn't exist and has a non-existent parent
        String invalidPath = "/nonexistent/parent/dir";

        assertThrows(IllegalArgumentException.class, () ->
                new WritableDirectorySetting("test.path", invalidPath, true));
    }

    @Test
    public void whenNonStrictModeWithInvalidDefaultThenConstructorSucceeds() {
        // Use a path that doesn't exist and has a non-existent parent
        String invalidPath = "/nonexistent/parent/dir";

        // Should not throw in non-strict mode
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", invalidPath, false);

        assertEquals(invalidPath, sut.getDefault());
    }

    // ========== Socket path tests ==========

    @Test
    public void whenPathIsUnixSocketThenValidationFails() throws IOException {
        // Skip on Windows where UNIX sockets are not supported
        assumeTrue(isNotWindowsOS());

        Path socketPath = tempFolder.getRoot().toPath().resolve("test.sock");

        // Create a UNIX domain socket server
        UnixDomainSocketAddress socketAddress = UnixDomainSocketAddress.of(socketPath);
        try (ServerSocketChannel serverChannel = ServerSocketChannel.open(StandardProtocolFamily.UNIX)) {
            serverChannel.bind(socketAddress);

            // Verify the socket file exists
            assertTrue("Socket file should exist", Files.exists(socketPath));

            // Test validate() directly - socket is not a directory
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                    () -> sut.validate(socketPath.toString()));
            assertThat(ex.getMessage(), containsString("must be a writable directory"));
            assertThat(ex.getMessage(), containsString("It is not a directory"));
        }
    }

    private static boolean isNotWindowsOS() {
        return !System.getProperty("os.name").toLowerCase().contains("windows");
    }
}
