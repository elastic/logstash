package org.logstash.instrument.witness;

import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link PipelinesWitness}
 */
public class PipelinesWitnessTest {

    private PipelinesWitness witness;

    @Before
    public void setup() {
        witness = new PipelinesWitness();
    }

    @Test
    public void testPipeline() {
        //once to create
        assertThat(witness.pipeline("default")).isNotNull();
        //again to assert it can pull from the map
        assertThat(witness.pipeline("default")).isNotNull();
    }

}