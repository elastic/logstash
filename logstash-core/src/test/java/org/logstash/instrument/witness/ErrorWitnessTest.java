package org.logstash.instrument.witness;

import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link ErrorWitness}
 */
public class ErrorWitnessTest {

    private ErrorWitness witness;

    @Before
    public void setup() {
        witness = new ErrorWitness();
    }

    @Test
    public void backtrace() {
        //as String
        witness.backtrace("foo");
        assertThat(witness.snitch().backtrace()).isEqualTo("foo");

        //as Exception
        RuntimeException exception = new RuntimeException("foobar");
        witness.backtrace(exception);
        for(StackTraceElement element : exception.getStackTrace()){
            assertThat(witness.snitch().backtrace()).contains(element.toString());
        }
    }

    @Test
    public void message() {
        witness.message("baz");
        assertThat(witness.snitch().message()).isEqualTo("baz");
    }
}