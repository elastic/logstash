package org.logstash.instrument.metrics;

import org.junit.Test;

import static org.hamcrest.core.Is.is;
import static org.junit.Assert.*;

/**
 * Created by andrewvc on 6/1/17.
 */
public class GaugeTest {
    @Test
    public void testInitialization() {
        Gauge<Integer> gauge = new Gauge<>(123);
        assertThat(gauge.get(), is(123));
    }

    @Test
    public void testSet() {
        Gauge<Integer> gauge = new Gauge<>(456);
        gauge.set(90210);
        assertThat(gauge.get(), is(90210));
    }
}