package org.logstash.instrument.witness;

import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link Witness}
 */
public class WitnessTest {
    private Witness witness;

    @Before
    public void setup(){
        Witness.setInstance(null);
    }

    @Test
    public void testInstance(){
        witness = new Witness();
        Witness.setInstance(witness);
        assertThat(Witness.instance()).isEqualTo(witness);
    }

    @Test(expected = IllegalStateException.class)
    public void testNoInstanceError(){
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
}