package org.logstash.instrument.witness;


import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link PluginWitness}
 */
public class PluginWitnessTest {

    private PluginWitness witness;

    @Before
    public void setup(){
        witness = new PluginWitness("123");
        assertThat(witness.snitch().id()).isEqualTo("123");
    }

    @Test
    public void testName(){
        assertThat(witness.name("abc")).isEqualTo(witness);
        assertThat(witness.snitch().name()).isEqualTo("abc");
    }

    @Test
    public void testEvents(){
        assertThat(witness.events()).isNotNull();
    }
}