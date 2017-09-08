package org.logstash.instrument.witness.pipeline;


import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link PluginsWitness}
 */
public class PluginsWitnessTest {

    private PluginsWitness witness;

    @Before
    public void setup(){
        witness = new PluginsWitness();
    }

    @Test
    public void testForget(){
        witness.inputs("1").events().in(99);
        assertThat(witness.inputs("1").events().snitch().in()).isEqualTo(99);
        witness.filters("1").events().in(98);
        assertThat(witness.filters("1").events().snitch().in()).isEqualTo(98);
        witness.outputs("1").events().in(97);
        assertThat(witness.outputs("1").events().snitch().in()).isEqualTo(97);
        witness.codecs("1").events().in(96);
        assertThat(witness.codecs("1").events().snitch().in()).isEqualTo(96);

        witness.forgetAll();

        assertThat(witness.inputs("1").events().snitch().in()).isEqualTo(0);
        assertThat(witness.filters("1").events().snitch().filtered()).isEqualTo(0);
        assertThat(witness.outputs("1").events().snitch().in()).isEqualTo(0);
        assertThat(witness.codecs("1").events().snitch().in()).isEqualTo(0);
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializeEmpty() throws Exception{
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[]}}");
    }

    @Test
    public void testSerializeInput() throws Exception{
        witness.inputs("foo");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[{\"id\":\"foo\",\"events\":{\"duration_in_millis\":0,\"in\":0,\"out\":0,\"filtered\":0," +
                "\"queue_push_duration_in_millis\":0},\"name\":null}],\"filters\":[],\"outputs\":[]}}");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[]}}");
    }

    @Test
    public void testSerializeFilters() throws Exception{
        witness.filters("foo");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[{\"id\":\"foo\",\"events\":{\"duration_in_millis\":0,\"in\":0,\"out\":0,\"filtered\":0," +
                "\"queue_push_duration_in_millis\":0},\"name\":null}],\"outputs\":[]}}");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[]}}");
    }

    @Test
    public void testSerializeOutputs() throws Exception{
        witness.outputs("foo");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[{\"id\":\"foo\",\"events\":{\"duration_in_millis\":0,\"in\":0,\"out\":0," +
                "\"filtered\":0,\"queue_push_duration_in_millis\":0},\"name\":null}]}}");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[]}}");
    }

    @Test
    public void testSerializeCodecs() throws Exception{
        witness.codecs("foo");
        String json = witness.asJson();
        //codecs are not currently serialized.
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[]}}");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).isEqualTo("{\"plugins\":{\"inputs\":[],\"filters\":[],\"outputs\":[]}}");
    }
}
