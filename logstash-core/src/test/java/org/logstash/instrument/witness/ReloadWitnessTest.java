package org.logstash.instrument.witness;


import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ReloadWitness}
 */
@RunWith(MockitoJUnitRunner.class)
public class ReloadWitnessTest {

    private ReloadWitness witness;
    private Timestamp timestamp = new Timestamp();
    @Mock
    JrubyTimestampExtLibrary.RubyTimestamp rubyTimestamp;

    @Before
    public void setup(){
        witness = new ReloadWitness();
        when(rubyTimestamp.getTimestamp()).thenReturn(timestamp);
    }

    @Test
    public void testSuccess(){
        witness.success();
        witness.lastSuccessTimestamp(rubyTimestamp);
        assertThat(witness.snitch().successes()).isEqualTo(1);
        assertThat(witness.snitch().lastSuccessTimestamp()).isEqualTo(timestamp);
        witness.successes(99);
        assertThat(witness.snitch().successes()).isEqualTo(100);
    }

    @Test
    public void testFailure(){
        witness.failure();
        witness.lastFailureTimestamp(rubyTimestamp);
        assertThat(witness.snitch().failures()).isEqualTo(1);
        assertThat(witness.snitch().lastFailureTimestamp()).isEqualTo(timestamp);
        witness.failures(99);
        assertThat(witness.snitch().failures()).isEqualTo(100);
    }

    @Test
    public void testError(){
        witness.error().message("foo");
        assertThat(witness.error().snitch().message()).isEqualTo("foo");
    }
}