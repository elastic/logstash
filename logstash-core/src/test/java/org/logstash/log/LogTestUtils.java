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


package org.logstash.log;

import org.apache.logging.log4j.core.LoggerContext;

import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.Assert.assertTrue;

class LogTestUtils {

    static String loadLogFileContent(String logfileName) throws IOException {
        Path path = FileSystems.getDefault()
                .getPath(System.getProperty("user.dir"), System.getProperty("ls.logs"), logfileName);

        assertTrue("Log [" + path.toString() + "] file MUST exists", Files.exists(path));
        try (Stream<String> lines = Files.lines(path)) {
            return lines.collect(Collectors.joining());
        }
    }

    static void reloadLogConfiguration() {
        LoggerContext context = LoggerContext.getContext(false);
        context.stop(1, TimeUnit.SECONDS); // this forces the Log4j config to be discarded
    }

    static void deleteLogFile(String logfileName) throws IOException {
        Path path = FileSystems.getDefault()
                .getPath(System.getProperty("user.dir"), System.getProperty("ls.logs"), logfileName);
        Files.deleteIfExists(path);
    }
}
