package com.logstash.pipeline;
import com.logstash.pipeline.graph.ConfigFile;
import com.logstash.pipeline.graph.Vertex;
import org.apache.commons.io.IOUtils;
import org.junit.Test;

import java.io.IOException;
import java.io.InputStream;

import static org.junit.Assert.*;

/**
 * Created by andrewvc on 2/20/16.
 */
public class PipelineGraphTest {
    public static PipelineGraph loadGraph(String configName) throws IOException, ConfigFile.InvalidGraphConfigFile {
        InputStream ymlStream =  ConfigFile.class.getResourceAsStream(configName);
        String ymlString = IOUtils.toString(ymlStream, "UTF-8");
        IOUtils.closeQuietly(ymlStream);

        return ConfigFile.fromString(ymlString, new TestComponentProcessor()).getPipelineGraph();
    }
    public static PipelineGraph loadSimpleGraph() throws IOException, ConfigFile.InvalidGraphConfigFile {
        return loadGraph("simple-graph-pipeline.yml");
    }

    public static PipelineGraph loadConditionalGraph() throws IOException, ConfigFile.InvalidGraphConfigFile {
        return loadGraph("conditional-graph-pipeline.yml");
    }

    @Test
    public void testGraphLoad() throws IOException, ConfigFile.InvalidGraphConfigFile {
        loadSimpleGraph();
    }

    @Test
    public void testConditionalGraphLoad() throws IOException, ConfigFile.InvalidGraphConfigFile {
        loadConditionalGraph();
    }

    @Test
    public void testGraphQueueGetReturnsQueue() throws IOException, ConfigFile.InvalidGraphConfigFile {
        assertEquals(loadSimpleGraph().queueVertex().getComponent().getType(), Component.Type.QUEUE);
    }

    @Test
    public void testPullingComponents() throws IOException, ConfigFile.InvalidGraphConfigFile {
        Component[] components = loadSimpleGraph().getComponents();
        assertEquals(components.length, loadSimpleGraph().getVertices().size());
    }

    @Test
    public void testQueueConnectedToOneComponent() throws IOException, ConfigFile.InvalidGraphConfigFile {
        Vertex qv = loadSimpleGraph().queueVertex();
        assertEquals(qv.getOutVertices().count(), 1);
    }
}
