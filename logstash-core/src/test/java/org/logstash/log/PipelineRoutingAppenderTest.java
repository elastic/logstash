package org.logstash.log;

import org.apache.logging.log4j.EventLogger;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.core.config.AppenderControl;
import org.apache.logging.log4j.core.config.Configuration;
import org.apache.logging.log4j.junit.LoggerContextRule;
import org.apache.logging.log4j.message.StructuredDataMessage;
import org.apache.logging.log4j.test.appender.ListAppender;
import org.junit.After;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.RuleChain;

import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

public class PipelineRoutingAppenderTest {

    private static final String CONFIG = "log4j-pipeline-routing.xml";

    private ListAppender app;

    private final LoggerContextRule loggerContextRule = new LoggerContextRule(CONFIG);

    // this is needed to initialize log context
    @Rule
    public RuleChain rules = loggerContextRule.withCleanFilesRule();

    @After
    public void tearDown() {
        this.app.clear();
        this.loggerContextRule.getLoggerContext().stop();
    }

    @Test
    public void routingTest() {
        final String pipelineId = "test_pipeline";
        StructuredDataMessage msg = new StructuredDataMessage("Test", "This is a test", "Service");
        org.apache.logging.log4j.ThreadContext.put("pipeline.id", pipelineId);
        EventLogger.logEvent(msg);

        this.app = findListAppender(pipelineId);
        assertEquals("appender-" + pipelineId, app.getName());

        final List<LogEvent> list = app.getEvents();
        assertNotNull("No events generated", list);
        assertEquals("Incorrect number of events. Expected 1, got " + list.size(), 1, list.size());
    }

    private ListAppender findListAppender(String pipelineId) {
        LoggerContext context = LoggerContext.getContext(false);
        final Configuration config = context.getConfiguration();
        PipelineRoutingAppender routingApp = config.getAppender("pipeline_routing");
        assertNotNull("Can't find pipeline routing appender", routingApp);
        Map<String, AppenderControl> appenders = routingApp.getAppenders();
        assertTrue("Subappender must exists with id " + pipelineId, appenders.containsKey(pipelineId));
        final AppenderControl appenderControl = appenders.get(pipelineId);
        return (ListAppender) appenderControl.getAppender();
    }

}