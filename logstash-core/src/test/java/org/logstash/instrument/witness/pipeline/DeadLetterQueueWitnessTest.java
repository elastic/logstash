package org.logstash.instrument.witness.pipeline;


import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link DeadLetterQueueWitness}
 */
public class DeadLetterQueueWitnessTest {

    private DeadLetterQueueWitness witness;

    @Before
    public void setup() {
        witness = new DeadLetterQueueWitness();
    }

    @Test
    public void queueSizeInBytes() {
        assertThat(witness.snitch().queueSizeInBytes()).isNull();
        witness.queueSizeInBytes(99);
        assertThat(witness.snitch().queueSizeInBytes()).isEqualTo(99l);
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"dead_letter_queue\":{\"queue_size_in_bytes\":0}}");
    }

    @Test
    public void testSerializeQueueSize() throws Exception {
        witness.queueSizeInBytes(98);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"dead_letter_queue\":{\"queue_size_in_bytes\":98}}");
    }
}
