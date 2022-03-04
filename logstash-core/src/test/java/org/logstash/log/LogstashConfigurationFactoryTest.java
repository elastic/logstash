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
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.ThreadContext;
import org.apache.logging.log4j.core.Appender;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.appender.routing.RoutingAppender;
import org.apache.logging.log4j.core.config.AppenderControl;
import org.apache.logging.log4j.core.config.Configuration;

import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.junit.*;

import java.util.List;
import java.util.Map;

import static junit.framework.TestCase.assertNotNull;
import static junit.framework.TestCase.assertNull;
import static junit.framework.TestCase.assertEquals;

public class LogstashConfigurationFactoryTest {

    private static final String CONFIG = "log4j2-log-pipeline-test.properties";

    private static Map<String, String> dumpedLog4jThreadContext;
    private static SystemPropsSnapshotHelper snapshotHelper = new SystemPropsSnapshotHelper();

    @BeforeClass
    public static void beforeClass() {
        snapshotHelper.takeSnapshot("log4j.configurationFile", "ls.log.format", "ls.logs",
                LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);
        dumpedLog4jThreadContext = ThreadContext.getImmutableContext();
    }

    @AfterClass
    public static void afterClass() {
        ThreadContext.putAll(dumpedLog4jThreadContext);
        snapshotHelper.restoreSnapshot("log4j.configurationFile", "ls.log.format", "ls.logs",
                LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);
    }

    @Before
    public void setUp() {
        System.setProperty("log4j.configurationFile", CONFIG);
        System.setProperty("ls.log.format", "plain");
        System.setProperty("ls.logs", "build/logs");
        System.setProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS, "true");

        ThreadContext.clearAll();
    }

    @Test
    public void testAppenderPerPipelineIsCreatedAfterLogLine() {
        forceLog4JContextRefresh();

        Logger logger = LogManager.getLogger(LogstashConfigurationFactoryTest.class);
        ThreadContext.put("pipeline.id", "pipeline_1");
        logger.info("log for pipeline 1");

        ThreadContext.remove("pipeline_1");
        ThreadContext.put("pipeline.id", "pipeline_2");
        logger.info("log for pipeline 2");

        verifyPipelineReceived("pipeline_1", "log for pipeline 1");
        verifyPipelineReceived("pipeline_2", "log for pipeline 2");
    }

    private void verifyPipelineReceived(String pipelineSubAppenderName, String expectedMessage) {
        LoggerContext context = LoggerContext.getContext(false);
        final Configuration config = context.getConfiguration();
        PipelineRoutingAppender routingApp = config.getAppender(LogstashConfigurationFactory.PIPELINE_ROUTING_APPENDER_NAME);
        Map<String, AppenderControl> appenders = routingApp.getAppenders();
        assertNotNull("Routing appenders MUST be defined", appenders);
        AppenderControl appenderControl = appenders.get(pipelineSubAppenderName);
        assertNotNull("sub-appender for pipeline " + pipelineSubAppenderName + " MUST be defined", appenderControl);
        Appender appender = appenderControl.getAppender();
        assertNotNull("Appender for pipeline " + pipelineSubAppenderName + " can't be NULL", appender);
        ListAppender pipeline1Appender = (ListAppender) appender;
        List<LogEvent> pipeline1LogEvents = pipeline1Appender.getEvents();
        assertEquals(1, pipeline1LogEvents.size());
        assertEquals(expectedMessage, pipeline1LogEvents.get(0).getMessage().getFormattedMessage());
    }

    @Test
    public void testDisableAppenderPerPipelineIsCreatedAfterLogLine() {
        System.setProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS, Boolean.FALSE.toString());
        forceLog4JContextRefresh();

        Logger logger = LogManager.getLogger(LogstashConfigurationFactoryTest.class);

        ThreadContext.put("pipeline.id", "pipeline_1");
        logger.info("log for pipeline 1");

        ThreadContext.remove("pipeline_1");
        ThreadContext.put("pipeline.id", "pipeline_2");
        logger.info("log for pipeline 2");

        LoggerContext context = LoggerContext.getContext(false);
        final Configuration config = context.getConfiguration();
        RoutingAppender routingApp = config.getAppender(LogstashConfigurationFactory.PIPELINE_ROUTING_APPENDER_NAME);
        assertNull("No routing appender should be present", routingApp);
    }

    private void forceLog4JContextRefresh() {
        LoggerContext context = LoggerContext.getContext(false);
        context.reconfigure();
    }

}