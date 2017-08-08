package org.logstash.instrument.witness;

import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link PipelineWitness}
 */
public class PipelineWitnessTest {

    private PipelineWitness witness;

    @Before
    public void setup(){
        witness = new PipelineWitness("default");
    }


    @Test
    public void testNotNull(){
        assertThat(witness.inputs("123")).isNotNull();
        assertThat(witness.filters("456")).isNotNull();
        assertThat(witness.outputs("789")).isNotNull();
        assertThat(witness.events()).isNotNull();
        assertThat(witness.plugins()).isNotNull();
        assertThat(witness.queue()).isNotNull();
        assertThat(witness.config()).isNotNull();
        assertThat(witness.reloads()).isNotNull();
    }

    @Test
    public void testForget(){
        witness.inputs("123").events().in(99);
        witness.filters("456").events().in(98);
        witness.outputs("789").events().in(97);
        assertThat(witness.inputs("123").events().snitch().in()).isEqualTo(99);
        assertThat(witness.filters("456").events().snitch().in()).isEqualTo(98);
        assertThat(witness.outputs("789").events().snitch().in()).isEqualTo(97);

        witness.events().in(99);
        witness.events().filtered(98);
        witness.events().out(97);
        assertThat(witness.events().snitch().in()).isEqualTo(99);
        assertThat(witness.events().snitch().filtered()).isEqualTo(98);
        assertThat(witness.events().snitch().out()).isEqualTo(97);

        witness.queue().type("memory");

        witness.forgetPlugins();
        witness.forgetEvents();

        assertThat(witness.inputs("123").events().snitch().in())
                .isEqualTo(witness.filters("456").events().snitch().in())
                .isEqualTo(witness.outputs("789").events().snitch().in())
                .isEqualTo(witness.events().snitch().in())
                .isEqualTo(witness.events().snitch().filtered())
                .isEqualTo(witness.events().snitch().out())
                .isEqualTo(0);

        assertThat(witness.queue().snitch().type()).isEqualTo("memory");
    }

}