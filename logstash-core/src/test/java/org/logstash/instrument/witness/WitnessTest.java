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
        assertThat(json).isEqualTo("{\"process\":{\"open_file_descriptors\":-1,\"peak_open_file_descriptors\":-1,\"max_file_descriptors\":-1," +
                "\"mem\":{\"total_virtual_in_bytes\":-1},\"cpu\":{\"total_in_millis\":-1,\"percent\":-1}},\"events\":{\"duration_in_millis\":0,\"in\":0,\"out\":0,\"filtered\":0," +
                "\"queue_push_duration_in_millis\":0},\"reloads\":{\"last_error\":{\"message\":null,\"backtrace\":null},\"successes\":0,\"last_success_timestamp\":null," +
                "\"last_failure_timestamp\":null,\"failures\":0},\"pipelines\":{}}");
    }

    @Test
    public void testSerializeEvents() throws Exception {
        witness = new Witness();
        witness.events().in(99);
        String json = witness.asJson();
        assertThat(json).contains("\"in\":99");
        witness.events().forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("99");
    }

    @Test
    public void testSerializePipelines() throws Exception {
        witness = new Witness();
        witness.pipeline("foo").events().in(98);
        witness.pipeline("foo").inputs("bar").events().in(99);
        String json = witness.asJson();
        assertThat(json).contains("\"pipelines\":{\"foo\"");
        //pipeline events
        assertThat(json).contains("foo").contains("in").contains(":98");
        //plugin events
        assertThat(json).contains("\"in\":99");
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