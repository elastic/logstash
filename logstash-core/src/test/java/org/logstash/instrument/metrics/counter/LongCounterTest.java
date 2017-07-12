package org.logstash.instrument.metrics.counter;

import org.junit.Before;
import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link LongCounter}
 */
public class LongCounterTest {

    private final long INITIAL_VALUE = 0l;
    private LongCounter longCounter;

    @Before
    public void _setup() {
        longCounter = new LongCounter(Collections.singletonList("foo"), "bar");
    }

    @Test
    public void getValue() {
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE);
    }

    @Test
    public void increment() {

        longCounter.increment();
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE + 1);
    }

    @Test(expected = UnsupportedOperationException.class)
    public void incrementByNegativeValue() {
        longCounter.increment(-100l);
    }

    @Test
    public void incrementByValue() {
        longCounter.increment(100l);
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE + 100);
    }

    @Test
    public void noInitialValue() {
        LongCounter counter = new LongCounter(Collections.singletonList("foo"), "bar");
        counter.increment();
        assertThat(counter.getValue()).isEqualTo(1l);
    }

    @Test
    @SuppressWarnings( "deprecation" )
    public void type() {
        assertThat(longCounter.type()).isEqualTo(MetricType.COUNTER_LONG.asString());
    }
}