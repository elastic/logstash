package org.logstash.log;

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.MarkerManager;
import org.apache.logging.log4j.core.Filter;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.config.Property;
import org.apache.logging.log4j.core.impl.Log4jLogEvent;
import org.apache.logging.log4j.message.SimpleMessage;
import org.junit.After;
import org.junit.Test;

import java.util.Collections;

import static org.junit.Assert.assertEquals;

public class PipelineRoutingFilterTest {

    @After
    public void tearDown() {
        System.clearProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS);
    }

    @Test
    public void testShouldLetEventFlowIfSeparateLogFeatureIsDisabled() {
        final PipelineRoutingFilter sut = PipelineRoutingFilter.createFilter();

        LogEvent log = new Log4jLogEvent();
        final Filter.Result res = sut.filter(log);

        assertEquals("When ls.pipeline.separate_logs is false the filter MUST be neutral", Filter.Result.NEUTRAL, res);
    }

    @Test
    public void testShouldLetEventFlowIfSeparateLogFeatureIsEnabledAndTheEventIsNotPipelineTagged() {
        System.setProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS, "true");
        final PipelineRoutingFilter sut = PipelineRoutingFilter.createFilter();

        LogEvent log = new Log4jLogEvent();
        final Filter.Result res = sut.filter(log);

        assertEquals("When ls.pipeline.separate_logs is enabled and log event is not tagged the filter MUST be neutral",
                Filter.Result.NEUTRAL, res);
    }

    @Test
    public void testDenyEventFlowIfSeparateLogFeatureIsEnabledAndTheEventIsPipelineTagged() {
        System.setProperty(LogstashConfigurationFactory.PIPELINE_SEPARATE_LOGS, "true");
        final PipelineRoutingFilter sut = PipelineRoutingFilter.createFilter();

        final Property prop = Property.createProperty("pipeline.id", "test_pipeline");

        LogEvent log = new Log4jLogEvent("logstash.test.filer",
                new MarkerManager.Log4jMarker("marker"), "a", Level.DEBUG,
                new SimpleMessage("test message"), Collections.singletonList(prop), null);
        final Filter.Result res = sut.filter(log);

        assertEquals("When ls.pipeline.separate_logs is enabled and log event is tagged the filter MUST deny the flowing",
                Filter.Result.DENY, res);
    }

}