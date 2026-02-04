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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * A setting that represents a writable directory path.
 * <p>
 * This setting validates that the specified path is a writable directory, or that it can be created.
 * When the value is accessed, the directory is created if it doesn't exist.
 * </p>
 */
public class WritableDirectorySetting extends BaseSetting<String> {

    private static final Logger LOGGER = LogManager.getLogger(WritableDirectorySetting.class);

    public WritableDirectorySetting(String name, String defaultValue) {
        this(name, defaultValue, false);
    }

    public WritableDirectorySetting(String name, String defaultValue, boolean strict) {
        super(name, defaultValue, strict, noValidator());
    }

    @Override
    public void validate(String input) throws IllegalArgumentException {
        if (input == null || input.isEmpty()) {
            throw new IllegalArgumentException(
                    String.format("Setting \"%s\" must be a non-empty String path.", getName()));
        }

        Path path = Paths.get(input);

        if (Files.isDirectory(path)) {
            if (!Files.isWritable(path)) {
                throw new IllegalArgumentException(
                        String.format("Path \"%s\" must be a writable directory. It is not writable.", input));
            }
            // it's a writable directory
            return;
        }

        // not a directory
        if (Files.isSymbolicLink(path)) {
            // Reject symlinks for safety - it's easier and safer to just reject them
            throw new IllegalArgumentException(
                    String.format("Path \"%s\" must be a writable directory. It cannot be a symlink.", input));
        }
        if (Files.exists(path)) {
            // Path exists but is not a directory (e.g., a file or socket)
            throw new IllegalArgumentException(
                    String.format("Path \"%s\" must be a writable directory. It is not a directory.", input));
        }
        // Path doesn't exist - check if parent is writable so we can create it
        Path parent = path.normalize().toAbsolutePath().getParent();
        if (parent == null || !Files.isWritable(parent)) {
            String parentPath = parent != null ? parent.toString() : "(no parent)";
            throw new IllegalArgumentException(
                    String.format("Path \"%s\" does not exist and cannot create it because the parent path \"%s\" is not writable.",
                            input, parentPath));
        }
    }

    @Override
    public String value() {
        String path = super.value();
        if (path != null) {
            if (path.isEmpty()) {
                // path.isEmpty() is here for compatibility with previous behavior, where Ruby's File.directory?("") is false.
                // So passing an empty string throws here an error instead of considering is as valid.
                throw new IllegalArgumentException("Path \"\" does not exist and directory creation failed");
            }
            Path dirPath = Paths.get(path);
            if (!Files.isDirectory(dirPath)) {
                // Create the directory if it doesn't exist
                try {
                    LOGGER.info("Creating directory for setting {}: {}", getName(), path);
                    Files.createDirectories(dirPath);
                } catch (IOException e) {
                    throw new IllegalArgumentException(
                            String.format("Path \"%s\" does not exist and directory creation failed: %s - %s",
                                    path, e.getClass().getName(), e.getMessage()), e);
                }
            }
        }
        return path;
    }
}
