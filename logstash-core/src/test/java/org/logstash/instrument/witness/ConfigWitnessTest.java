package org.logstash.instrument.witness;

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

}