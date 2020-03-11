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

import org.apache.logging.log4j.LogManager;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.After;

import java.io.IOException;

import static org.junit.Assert.assertTrue;

public class DefaultDeprecationLoggerTest {

    private static final String CONFIG = "log4j2-log-deprecation-test.properties";
    private static SystemPropsSnapshotHelper snapshotHelper = new SystemPropsSnapshotHelper();

    @BeforeClass
    public static void beforeClass() {
        snapshotHelper.takeSnapshot("log4j.configurationFile", "ls.log.format", "ls.logs",
                LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);
        LogTestUtils.reloadLogConfiguration();
    }

    @AfterClass
    public static void afterClass() {
        snapshotHelper.restoreSnapshot("log4j.configurationFile", "ls.log.format", "ls.logs",
                LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);
    }

    @Before
    public void setUp() throws IOException {
        System.setProperty("log4j.configurationFile", CONFIG);
        System.setProperty("ls.log.format", "plain");
        System.setProperty("ls.logs", "build/logs");

        LogTestUtils.deleteLogFile("logstash-deprecation.log");
    }

    @After
    public void tearDown() throws IOException {
        LogManager.shutdown();
        LogTestUtils.deleteLogFile("logstash-deprecation.log");
        LogTestUtils.reloadLogConfiguration();
    }

    @Test
    public void testDeprecationLoggerWriteOut_root() throws IOException {
        final DefaultDeprecationLogger deprecationLogger = new DefaultDeprecationLogger(LogManager.getLogger("test"));

        // Exercise
        deprecationLogger.deprecated("Simple deprecation message");

        String logs = LogTestUtils.loadLogFileContent("logstash-deprecation.log");
        assertTrue("Deprecation logs MUST contains the out line", logs.matches(".*\\[deprecation\\.test.*\\].*Simple deprecation message"));
    }

    @Test
    public void testDeprecationLoggerWriteOut_nested() throws IOException {
        final DefaultDeprecationLogger deprecationLogger = new DefaultDeprecationLogger(LogManager.getLogger("org.logstash.my_nested_logger"));

        // Exercise
        deprecationLogger.deprecated("Simple deprecation message");

        String logs = LogTestUtils.loadLogFileContent("logstash-deprecation.log");
        assertTrue("Deprecation logs MUST contains the out line", logs.matches(".*\\[org\\.logstash\\.deprecation\\.my_nested_logger.*\\].*Simple deprecation message"));
    }
}