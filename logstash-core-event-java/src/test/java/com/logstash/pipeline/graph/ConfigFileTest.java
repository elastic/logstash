package com.logstash.pipeline.graph;

import com.logstash.pipeline.PipelineGraph;
import com.logstash.pipeline.TestComponentProcessor;
import org.apache.commons.io.IOUtils;
import org.junit.Test;

import java.io.InputStream;
import java.net.URL;

import static org.junit.Assert.assertEquals;

/**
 * Created by andrewvc on 2/21/16.
 */
public class ConfigFileTest {
    @Test
    public void testSimpleParse() throws Exception, ConfigFile.InvalidGraphConfigFile {
        InputStream ymlStream =  this.getClass().getResourceAsStream("simple-graph-pipeline.yml");
        String ymlString = IOUtils.toString(ymlStream, "UTF-8");
        IOUtils.closeQuietly(ymlStream);

        ConfigFile f = ConfigFile.fromString(ymlString, new TestComponentProcessor());
        assertEquals(f, f);
    }

}
