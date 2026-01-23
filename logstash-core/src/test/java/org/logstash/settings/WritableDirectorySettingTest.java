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

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.junit.Assert.*;
import static org.junit.Assume.assumeTrue;

public class WritableDirectorySettingTest {

    @Rule
    public TemporaryFolder tempFolder = new TemporaryFolder();

    // ========== validate() tests for existing directories ==========

    @Test
    public void whenDirectoryExistsAndIsWritableThenValidationPasses() throws IOException {
        Path existingDir = tempFolder.newFolder("existing").toPath();
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);

        sut.set(existingDir.toString());

        // Should not throw
        sut.validateValue();
    }

    @Test
    public void whenDirectoryExistsButNotWritableThenValidationFails() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(!System.getProperty("os.name").toLowerCase().contains("windows"));

        Path existingDir = tempFolder.newFolder("readonly").toPath();
        File dirFile = existingDir.toFile();
        assumeTrue("Could not set directory to read-only", dirFile.setWritable(false));

        try {
            WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
            sut.set(existingDir.toString());

            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
            assertThat(ex.getMessage(), containsString("must be a writable directory"));
            assertThat(ex.getMessage(), containsString("It is not writable"));
        } finally {
            // Restore permissions for cleanup
            dirFile.setWritable(true);
        }
    }

    // ========== validate() tests for existing paths ==========

    @Test
    public void whenPathExistsButIsFileThenValidateFails() throws IOException {
        Path filePath = tempFolder.newFile("afile.txt").toPath();
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);

        // Test validate() directly for specific validation error
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> sut.validate(filePath.toString()));
        assertThat(ex.getMessage(), containsString("must be a writable directory"));
        assertThat(ex.getMessage(), containsString("It is not a directory"));
    }

    @Test
    public void whenPathExistsButIsFileThenValidateValueFails() throws IOException {
        Path filePath = tempFolder.newFile("afile.txt").toPath();
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);

        sut.set(filePath.toString());

        // validateValue() calls value() first which tries to create directory at file path
        // This fails with FileAlreadyExistsException wrapped in IllegalArgumentException
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("failed trying to create it"));
    }

    @Test
    public void whenPathIsSymlinkToNonExistentTargetThenValidationFails() throws IOException {
        // Skip on Windows where symlinks require special permissions
        assumeTrue(!System.getProperty("os.name").toLowerCase().contains("windows"));

        // Create symlink to non-existent target (like Ruby test does with "whatever")
        Path symlink = tempFolder.getRoot().toPath().resolve("symlink");
        Files.createSymbolicLink(symlink, tempFolder.getRoot().toPath().resolve("nonexistent"));

        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);

        // Test validate() directly for specific validation error
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> sut.validate(symlink.toString()));
        assertThat(ex.getMessage(), containsString("must be a writable directory"));
        assertThat(ex.getMessage(), containsString("cannot be a symlink"));
    }

    @Test
    public void whenPathIsSymlinkToExistingDirectoryThenValidationPasses() throws IOException {
        // Skip on Windows where symlinks require special permissions
        assumeTrue(!System.getProperty("os.name").toLowerCase().contains("windows"));

        // Symlink to existing directory - Files.isDirectory() follows symlinks
        // so this is treated as a valid directory (matching Ruby behavior where
        // File.directory? also follows symlinks)
        Path targetDir = tempFolder.newFolder("target").toPath();
        Path symlink = tempFolder.getRoot().toPath().resolve("symlink");
        Files.createSymbolicLink(symlink, targetDir);

        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);

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

        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
        sut.set(missingDir.toString());

        // Should not throw - validation passes because parent is writable
        sut.validateValue();
    }

    @Test
    public void whenDirectoryMissingAndParentNotWritableThenValidateFails() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(!System.getProperty("os.name").toLowerCase().contains("windows"));

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("missing");
        File parentFile = parentDir.toFile();
        assumeTrue("Could not set parent directory to read-only", parentFile.setWritable(false));

        try {
            WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);

            // Test validate() directly for specific validation error
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                    () -> sut.validate(missingDir.toString()));
            assertThat(ex.getMessage(), containsString("does not exist and I cannot create it"));
            assertThat(ex.getMessage(), containsString("parent path"));
            assertThat(ex.getMessage(), containsString("is not writable"));
        } finally {
            // Restore permissions for cleanup
            parentFile.setWritable(true);
        }
    }

    @Test
    public void whenDirectoryMissingAndParentNotWritableThenValidateValueFails() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(!System.getProperty("os.name").toLowerCase().contains("windows"));

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("missing");
        File parentFile = parentDir.toFile();
        assumeTrue("Could not set parent directory to read-only", parentFile.setWritable(false));

        try {
            WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
            sut.set(missingDir.toString());

            // validateValue() calls value() first which tries to create directory
            // and fails because parent is not writable
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
            assertThat(ex.getMessage(), containsString("failed trying to create it"));
        } finally {
            // Restore permissions for cleanup
            parentFile.setWritable(true);
        }
    }

    // ========== validate() tests for null and empty ==========

    @Test
    public void whenPathIsNullThenValidationFails() {
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
        sut.set(null);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("must be a non-empty String path"));
    }

    @Test
    public void whenPathIsEmptyThenValidationFails() {
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
        sut.set("");

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::validateValue);
        assertThat(ex.getMessage(), containsString("must be a non-empty String path"));
    }

    // ========== value() tests ==========

    @Test
    public void whenDirectoryMissingAndParentWritableThenValueCreatesDirectory() throws IOException {
        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("newdir");

        assertFalse(Files.exists(missingDir));

        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
        sut.set(missingDir.toString());

        // Calling value() should create the directory
        String result = sut.value();

        assertEquals(missingDir.toString(), result);
        assertTrue("Directory should have been created", Files.isDirectory(missingDir));
    }

    @Test
    public void whenDirectoryAlreadyExistsThenValueReturnsPath() throws IOException {
        Path existingDir = tempFolder.newFolder("existing").toPath();

        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
        sut.set(existingDir.toString());

        String result = sut.value();

        assertEquals(existingDir.toString(), result);
        assertTrue(Files.isDirectory(existingDir));
    }

    @Test
    public void whenDirectoryCannotBeCreatedThenValueThrows() throws IOException {
        // Skip on Windows where chmod doesn't work the same way
        assumeTrue(!System.getProperty("os.name").toLowerCase().contains("windows"));

        Path parentDir = tempFolder.newFolder("parent").toPath();
        Path missingDir = parentDir.resolve("newdir");
        File parentFile = parentDir.toFile();

        // First set the value, then make parent read-only
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", "", false);
        sut.set(missingDir.toString());

        assumeTrue("Could not set parent directory to read-only", parentFile.setWritable(false));

        try {
            IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, sut::value);
            assertThat(ex.getMessage(), containsString("does not exist, and I failed trying to create it"));
        } finally {
            // Restore permissions for cleanup
            parentFile.setWritable(true);
        }
    }

    // ========== Constructor tests ==========

    @Test
    public void whenStrictModeWithValidDefaultThenConstructorSucceeds() throws IOException {
        Path existingDir = tempFolder.newFolder("valid").toPath();

        // Should not throw - default value is valid
        WritableDirectorySetting sut = new WritableDirectorySetting("test.path", existingDir.toString(), true);

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
}
