package org.logstash.instrument.witness;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link Witness}
 */
public class WitnessTest {
    private Witness witness;

    @Before
    public void setup() {
        Witness.setInstance(null);
    }

    @Test
    public void testInstance() {
        witness = new Witness();
        Witness.setInstance(witness);
        assertThat(Witness.instance()).isEqualTo(witness);
    }

    @Test(expected = IllegalStateException.class)
    public void testNoInstanceError() {
        Witness.instance();
    }

    @Test
    public void testNotNull() {
        witness = new Witness();
        Witness.setInstance(witness);
        assertThat(witness.events()).isNotNull();
        assertThat(witness.reloads()).isNotNull();
        assertThat(witness.pipelines()).isNotNull();
        assertThat(witness.pipeline("foo")).isNotNull();
    }

    @Test
    public void testAsJson() throws Exception {
        witness = new Witness();
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        witness = new Witness();
        String json = witness.asJson();
        //empty pipelines
        assertThat(json).contains("\"pipelines\":{}");
        //non-empty reloads
        assertThat(json).contains("{\"reloads\":{\"");
        //no events
        assertThat(json).doesNotContain("events");
    }

    @Test
    public void testSerializeEvents() throws Exception {
        witness = new Witness();
        witness.events().in(99);
        String json = witness.asJson();
        assertThat(json).contains("{\"events\":{\"in\":99}");
        witness.events().forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("events");
    }

    @Test
    public void testSerializePipelines() throws Exception {
        witness = new Witness();
        witness.pipeline("foo").events().in(98);
        witness.pipeline("foo").inputs("bar").events().in(99);
        String json = witness.asJson();
        assertThat(json).contains("\"pipelines\":{\"foo\"");
        //pipeline events
        assertThat(json).contains("\"foo\":{\"events\":{\"in\":98");
        //plugin events
        assertThat(json).contains("plugins\":{\"inputs\":[{\"id\":\"bar\",\"events\":{\"in\":99");
        //forget events
        witness.pipeline("foo").forgetEvents();
        json = witness.asJson();
        assertThat(json).doesNotContain("98");
        //forget plugins
        witness.pipeline("foo").forgetPlugins();
        json = witness.asJson();
        assertThat(json).doesNotContain("99");
        //pipelines still there
        assertThat(json).contains("\"pipelines\":{\"foo\"");
    }
}