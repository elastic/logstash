package org.logstash.instrument.witness;


import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link PluginWitness}
 */
public class PluginWitnessTest {

    private PluginWitness witness;

    @Before
    public void setup(){
        witness = new PluginWitness("123");
        assertThat(witness.snitch().id()).isEqualTo("123");
    }

    @Test
    public void testName(){
        assertThat(witness.name("abc")).isEqualTo(witness);
        assertThat(witness.snitch().name()).isEqualTo("abc");
    }

    @Test
    public void testEvents(){
        assertThat(witness.events()).isNotNull();
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializationEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"id\":\"123\"}");
    }

    @Test
    public void testSerializationName() throws Exception {
        witness.name("abc");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"id\":\"123\",\"name\":\"abc\"}");
    }

    @Test
    public void testSerializationEvents() throws Exception {
        witness.events().in();
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"id\":\"123\",\"events\":{\"in\":1}}");
    }
}