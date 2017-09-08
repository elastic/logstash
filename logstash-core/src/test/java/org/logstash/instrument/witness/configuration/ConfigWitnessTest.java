package org.logstash.instrument.witness.configuration;

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
        assertThat(witness.snitch().batchDelay()).isNull();
        witness.batchDelay(99);
        assertThat(witness.snitch().batchDelay()).isEqualTo(99l);
    }

    @Test
    public void testBatchSize() {
        assertThat(witness.snitch().batchSize()).isNull();
        witness.batchSize(98);
        assertThat(witness.snitch().batchSize()).isEqualTo(98l);
    }

    @Test
    public void testConfigReloadAutomatic() {
        assertThat(witness.snitch().configReloadAutomatic()).isFalse();
        witness.configReloadAutomatic(true);
        assertThat(witness.snitch().configReloadAutomatic()).isTrue();
        witness.configReloadAutomatic(false);
        assertThat(witness.snitch().configReloadAutomatic()).isFalse();
    }

    @Test
    public void testConfigReloadInterval() {
        assertThat(witness.snitch().configReloadInterval()).isNull();
        witness.configReloadInterval(97);
        assertThat(witness.snitch().configReloadInterval()).isEqualTo(97l);
    }

    @Test
    public void testDeadLetterQueueEnabled() {
        assertThat(witness.snitch().deadLetterQueueEnabled()).isFalse();
        witness.deadLetterQueueEnabled(true);
        assertThat(witness.snitch().deadLetterQueueEnabled()).isTrue();
        witness.deadLetterQueueEnabled(false);
        assertThat(witness.snitch().deadLetterQueueEnabled()).isFalse();
    }

    @Test
    public void testDeadLetterQueuePath() {
        assertThat(witness.snitch().deadLetterQueuePath()).isNull();
        witness.deadLetterQueuePath("/var/dlq");
        assertThat(witness.snitch().deadLetterQueuePath()).isEqualTo("/var/dlq");
    }

    @Test
    public void testWorkers() {
        assertThat(witness.snitch().workers()).isNull();
        witness.workers(96);
        assertThat(witness.snitch().workers()).isEqualTo(96l);
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson()).contains("config");
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":0,\"batch_delay\":0,\"config_reload_interval\":0,\"config_reload_automatic\":false," +
                "\"dead_letter_queue_enabled\":false,\"dead_letter_queue_path\":null}}");
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
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":888,\"batch_delay\":0,\"config_reload_interval\":0,\"config_reload_automatic\":false," +
                "\"dead_letter_queue_enabled\":false,\"dead_letter_queue_path\":null}}");
    }

    @Test
    public void testSerializeBatchDelay() throws Exception {
        witness.batchDelay(777);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":0,\"batch_delay\":777,\"config_reload_interval\":0,\"config_reload_automatic\":false," +
                "\"dead_letter_queue_enabled\":false,\"dead_letter_queue_path\":null}}");
    }

    @Test
    public void testSerializeAutoConfigReload() throws Exception {
        witness.configReloadAutomatic(true);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":0,\"batch_delay\":0,\"config_reload_interval\":0,\"config_reload_automatic\":true," +
                "\"dead_letter_queue_enabled\":false,\"dead_letter_queue_path\":null}}");
    }

    @Test
    public void testSerializeReloadInterval() throws Exception {
        witness.configReloadInterval(666);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":0,\"batch_delay\":0,\"config_reload_interval\":666,\"config_reload_automatic\":false," +
                "\"dead_letter_queue_enabled\":false,\"dead_letter_queue_path\":null}}");
    }

    @Test
    public void testSerializeEnableDeadLetterQueue() throws Exception {
        witness.deadLetterQueueEnabled(true);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":0,\"batch_delay\":0,\"config_reload_interval\":0,\"config_reload_automatic\":false," +
                "\"dead_letter_queue_enabled\":true,\"dead_letter_queue_path\":null}}");
    }

    @Test
    public void testSerializeEnableDeadLetterPath() throws Exception {
        witness.deadLetterQueuePath("/var/dlq");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"config\":{\"batch_size\":0,\"workers\":0,\"batch_delay\":0,\"config_reload_interval\":0,\"config_reload_automatic\":false," +
                "\"dead_letter_queue_enabled\":false,\"dead_letter_queue_path\":\"/var/dlq\"}}");
    }

}
