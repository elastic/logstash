package org.logstash.instrument.witness;


import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link QueueWitness}
 */
public class QueueWitnessTest {

    private QueueWitness witness;

    @Before
    public void setup(){
        witness = new QueueWitness();
    }
    @Test
    public void testType(){
        witness.type("memory");
        assertThat(witness.snitch().type()).isEqualTo("memory");
    }

}