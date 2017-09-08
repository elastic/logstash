package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link PipelinesWitness}
 */
public class PipelinesWitnessTest {

    private PipelinesWitness witness;

    @Before
    public void setup() {
        witness = new PipelinesWitness();
    }

    @Test
    public void testPipeline() {
        //once to create
        assertThat(witness.pipeline("default")).isNotNull();
        //again to assert it can pull from the map
        assertThat(witness.pipeline("default")).isNotNull();
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson()).contains("pipelines");
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"pipelines\":{}}");
    }

    @Test
    public void testSerializePipelines() throws Exception {
        witness.pipeline("aaa");
        witness.pipeline("bbb");
        witness.pipeline("ccc");
        String json = witness.asJson();
        assertThat(json).contains("aaa").contains("bbb").contains("ccc");
    }

}
