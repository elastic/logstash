package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link EventsWitness}
 */
public class EventsWitnessTest {

    private EventsWitness witness;

    @Before
    public void setup() {
        witness = new EventsWitness();
    }

    @Test
    public void testDuration() {
        witness.duration(99);
        assertThat(witness.snitch().duration()).isEqualTo(99);
        witness.duration(1);
        assertThat(witness.snitch().duration()).isEqualTo(100);
    }

    @Test
    public void testFiltered() {
        witness.filtered(88);
        assertThat(witness.snitch().filtered()).isEqualTo(88);
        witness.filtered();
        assertThat(witness.snitch().filtered()).isEqualTo(89);
    }

    @Test
    public void testForget() {
        witness.duration(99);
        witness.filtered(88);
        witness.in(66);
        witness.out(55);
        witness.queuePushDuration(44);

        assertThat(witness.snitch().duration()).isEqualTo(99);
        assertThat(witness.snitch().in()).isEqualTo(66);
        assertThat(witness.snitch().out()).isEqualTo(55);
        assertThat(witness.snitch().queuePushDuration()).isEqualTo(44);

        witness.forgetAll();

        assertThat(witness.snitch().duration()).isEqualTo(0);
        assertThat(witness.snitch().in()).isEqualTo(0);
        assertThat(witness.snitch().out()).isEqualTo(0);
        assertThat(witness.snitch().queuePushDuration()).isEqualTo(0);
    }

    @Test
    public void testIn() {
        witness.in(66);
        assertThat(witness.snitch().in()).isEqualTo(66);
        witness.in();
        assertThat(witness.snitch().in()).isEqualTo(67);
    }

    @Test
    public void testOut() {
        witness.out(55);
        assertThat(witness.snitch().out()).isEqualTo(55);
        witness.out();
        assertThat(witness.snitch().out()).isEqualTo(56);
    }

    @Test
    public void testQueuePushDuration() {
        witness.queuePushDuration(44);
        assertThat(witness.snitch().queuePushDuration()).isEqualTo(44);
        witness.queuePushDuration(1);
        assertThat(witness.snitch().queuePushDuration()).isEqualTo(45);
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        //empty
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
        //dirty
        witness.in(1);
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson()).contains("events");
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        assertThat(witness.asJson()).isNotEmpty();
    }

    @Test
    public void testSerializeDuration() throws Exception {
        witness.duration(999);
        String json = witness.asJson();
        assertThat(json).contains("999");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("999");
    }

    @Test
    public void testSerializeIn() throws Exception {
        witness.in(888);
        String json = witness.asJson();
        assertThat(json).contains("888");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("888");
    }

    @Test
    public void testSerializeFiltered() throws Exception {
        witness.filtered(777);
        String json = witness.asJson();
        assertThat(json).contains("777");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("777");
    }

    @Test
    public void testSerializeOut() throws Exception {
        witness.out(666);
        String json = witness.asJson();
        assertThat(json).contains("666");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("666");
    }

    @Test
    public void testSerializeQueueDuration() throws Exception {
        witness.queuePushDuration(555);
        String json = witness.asJson();
        assertThat(json).contains("555");
        witness.forgetAll();
        json = witness.asJson();
        assertThat(json).doesNotContain("555");
    }

}
