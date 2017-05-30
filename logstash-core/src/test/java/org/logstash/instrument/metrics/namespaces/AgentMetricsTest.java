package org.logstash.instrument.metrics.namespaces;

import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.core.Is.is;
import static org.hamcrest.core.IsNull.notNullValue;

/**
 * Created by andrewvc on 5/31/17.
 */
public class AgentMetricsTest {
    AgentMetrics agent;

    @Before
    public void make() {
        agent = new AgentMetrics(new TestMetricFactory());
    }

    @Test
    public void testAddingPipeline() {
        agent.addPipeline("foo");
        PipelineMetrics pipelineMetrics = agent.getPipelineMetrics("foo");
        assertThat(pipelineMetrics, is(notNullValue()));
    }
}
