package org.logstash.instrument.witness;


import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link PluginsWitness}
 */
public class PluginsWitnessTest {

    private PluginsWitness witness;

    @Before
    public void setup(){
        witness = new PluginsWitness();
    }

    @Test
    public void testForget(){
        witness.inputs("1").events().in(99);
        assertThat(witness.inputs("1").events().snitch().in()).isEqualTo(99);
        witness.filters("1").events().in(98);
        assertThat(witness.filters("1").events().snitch().in()).isEqualTo(98);
        witness.outputs("1").events().in(97);
        assertThat(witness.outputs("1").events().snitch().in()).isEqualTo(97);

        witness.forgetAll();

        assertThat(witness.inputs("1").events().snitch().in()).isEqualTo(0);
        assertThat(witness.filters("1").events().snitch().filtered()).isEqualTo(0);
        assertThat(witness.outputs("1").events().snitch().in()).isEqualTo(0);
    }
}