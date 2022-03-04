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


package org.logstash.benchmark.cli.util;

import java.io.File;
import java.io.IOException;
import org.apache.commons.io.FileUtils;

/**
 * Utility class for file handling.
 */
public final class LsBenchFileUtil {

    private LsBenchFileUtil() {
        //Utility Class
    }

    public static void ensureDeleted(final File file) throws IOException {
        if (file.exists()) {
            if (file.isDirectory()) {
                FileUtils.deleteDirectory(file);
            } else {
                if (!file.delete()) {
                    throw new IllegalStateException(
                        String.format("Failed to delete %s", file.getAbsolutePath())
                    );
                }
            }
        }
    }

    public static void ensureExecutable(final File file) {
        if (!file.canExecute() && !file.setExecutable(true)) {
            throw new IllegalStateException(
                String.format("Failed to set %s executable", file.getAbsolutePath()));
        }
    }
}
