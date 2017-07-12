package org.logstash.instrument.metrics;

import org.junit.Before;
import org.junit.Test;

import static org.hamcrest.core.Is.is;
import static org.junit.Assert.*;

/**
 * Created by andrewvc on 6/1/17.
 */
public class CounterTest {
    Counter counter;

    @Before
    public void init() {
        counter = new Counter(0);
    }

    @Test
    public void testInitialization() {
        Counter counter = new Counter(123);
        assertThat(counter.get(), is(123L));
    }

    @Test
    public void testIncrement() {
        counter.increment();
        assertThat(counter.get(), is(1L));
    }

    @Test
    public void testParameterizedIncrement() {
        counter.increment(456);
        assertThat(counter.get(), is(456L));
    }

    @Test
    public void testDecrement() {
        counter.decrement();
        assertThat(counter.get(), is(-1L));
    }

    @Test
    public void testParameterizedDecrement() {
        counter.decrement(456);
        assertThat(counter.get(), is(-456L));
    }

}