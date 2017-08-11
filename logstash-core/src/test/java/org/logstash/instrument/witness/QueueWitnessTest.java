package org.logstash.instrument.witness;


import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link QueueWitness}
 */
public class QueueWitnessTest {

    private QueueWitness witness;

    @Before
    public void setup(){
        witness = new QueueWitness();
    }
    @Test
    public void testType(){
        witness.type("memory");
        assertThat(witness.snitch().type()).isEqualTo("memory");
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializeEmpty() throws Exception{
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"queue\":{}}");
    }

    @Test
    public void testSerializeType() throws Exception{
        witness.type("memory");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"queue\":{\"type\":\"memory\"}}");
    }

}