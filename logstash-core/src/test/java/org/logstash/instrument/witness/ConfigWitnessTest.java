package org.logstash.instrument.witness;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link ConfigWitness}
 */
public class ConfigWitnessTest {

    private ConfigWitness witness;

    @Before
    public void setup() {
        witness = new ConfigWitness();
    }

    @Test
    public void testBatchDelay() {
        witness.batchDelay(99);
        assertThat(witness.snitch().batchDelay()).isEqualTo(99);
    }

    @Test
    public void testBatchSize() {
        witness.batchSize(98);
        assertThat(witness.snitch().batchSize()).isEqualTo(98);
    }

    @Test
    public void testConfigReloadAutomatic() {
        witness.configReloadAutomatic(true);
        assertThat(witness.snitch().configReloadAutomatic()).isTrue();
        witness.configReloadAutomatic(false);
        assertThat(witness.snitch().configReloadAutomatic()).isFalse();
    }

    @Test
    public void testConfigReloadInterval() {
        witness.configReloadInterval(97);
        assertThat(witness.snitch().configReloadInterval()).isEqualTo(97);
    }

    @Test
    public void testDeadLetterQueueEnabled() {
        witness.deadLetterQueueEnabled(true);
        assertThat(witness.snitch().deadLetterQueueEnabled()).isTrue();
        witness.deadLetterQueueEnabled(false);
        assertThat(witness.snitch().deadLetterQueueEnabled()).isFalse();
    }

    @Test
    public void testWorkers() {
        witness.workers(96);
        assertThat(witness.snitch().workers()).isEqualTo(96);
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson()).contains("config");
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{}}");
    }

    @Test
    public void testSerializeBatchSize() throws Exception {
        witness.batchSize(999);
        String json = witness.asJson();
        assertThat(json).contains("999");
    }

    @Test
    public void testSerializeWorkersSize() throws Exception {
        witness.workers(888);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"workers\":888}}");
    }

    @Test
    public void testSerializeBatchDelay() throws Exception {
        witness.batchDelay(777);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_delay\":777}}");
    }

    @Test
    public void testSerializeAutoConfigReload() throws Exception {
        witness.configReloadAutomatic(true);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"config_reload_automatic\":true}}");
    }

    @Test
    public void testSerializeReloadInterval() throws Exception {
        witness.configReloadInterval(666);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"config_reload_interval\":666}}");
    }

    @Test
    public void testSerializeEnableDeadLetterQueue() throws Exception {
        witness.deadLetterQueueEnabled(true);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"dead_letter_queue_enabled\":true}}");
    }

}