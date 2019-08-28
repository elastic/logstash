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

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static junit.framework.TestCase.assertNotNull;
import static junit.framework.TestCase.assertNull;
import static junit.framework.TestCase.assertEquals;

public class LogstashConfigurationFactoryTest {

    private static final String CONFIG = "log4j2-log-pipeline-test.properties";

    private static Map<String, String> systemPropertiesDump = new HashMap<>();
    private static Map<String, String> dumpedLog4jThreadContext;

    @BeforeClass
    public static void beforeClass() {
        dumpSystemProperty("log4j.configurationFile");
        dumpSystemProperty("ls.log.format");
        dumpSystemProperty("ls.logs");
        dumpSystemProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);

        dumpedLog4jThreadContext = ThreadContext.getImmutableContext();
    }

    private static void dumpSystemProperty(String propertyName) {
        systemPropertiesDump.put(propertyName, System.getProperty(propertyName));
    }

    @AfterClass
    public static void afterClass() {
        ThreadContext.putAll(dumpedLog4jThreadContext);

        restoreSystemProperty("log4j.configurationFile");
        restoreSystemProperty("ls.log.format");
        restoreSystemProperty("ls.logs");
        restoreSystemProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);
    }

    private static void restoreSystemProperty(String propertyName) {
        if (systemPropertiesDump.get(propertyName) == null) {
            System.clearProperty(propertyName);
        } else {
            System.setProperty(propertyName, systemPropertiesDump.get(propertyName));
        }
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
        RoutingAppender routingApp = config.getAppender(LogstashConfigurationFactory.PIPELINE_ROUTING_APPENDER_NAME);
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