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

import org.junit.*;
import org.logstash.Event;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.ContextImpl;

import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertTrue;

public class PluginDeprecationLoggerTest {

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
        LogTestUtils.reloadLogConfiguration();
        LogTestUtils.deleteLogFile("logstash-deprecation.log");
    }

    @Test
    public void testJavaPluginUsesDeprecationLogger() throws IOException {
        Map<String, Object> config = new HashMap<>();
        TestingDeprecationPlugin sut = new TestingDeprecationPlugin(new ConfigurationImpl(config), new ContextImpl(null, null));

        // Exercise
        Event evt = new Event(Collections.singletonMap("message", "Spock move me back"));
        sut.encode(evt, null);

        // Verify
        String logs = LogTestUtils.loadLogFileContent("logstash-deprecation.log");
        assertTrue("Deprecation logs MUST contains the out line", logs.matches(".*Deprecated feature teleportation"));
    }
}
