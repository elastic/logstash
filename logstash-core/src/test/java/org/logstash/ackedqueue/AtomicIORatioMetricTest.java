package org.logstash.ackedqueue;

import org.apache.logging.log4j.Logger;
import org.junit.Test;
import org.mockito.Mockito;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.stringContainsInOrder;
import static org.mockito.Matchers.argThat;
import static org.mockito.Matchers.eq;

public class AtomicIORatioMetricTest {
    @Test
    public void test() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");

        assertThat(ioRatioMetric.getValue()).isNaN();

        ioRatioMetric.incrementBy(1024, 768);
        assertThat(ioRatioMetric.getValue()).isEqualTo(0.75);

        ioRatioMetric.incrementBy(256, 128);
        assertThat(ioRatioMetric.getValue()).isEqualTo(0.7);

        ioRatioMetric.incrementBy(512, 128);
        assertThat(ioRatioMetric.getValue()).isEqualTo(0.5714);

        ioRatioMetric.incrementBy(256, 0);
        assertThat(ioRatioMetric.getValue()).isEqualTo(0.5);

        ioRatioMetric.incrementBy(0, 1024);
        assertThat(ioRatioMetric.getValue()).isEqualTo(1.0);

        ioRatioMetric.reset();
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(0L);
            assertThat(value.bytesOut()).isEqualTo(0L);
        });

        int iterations = 100000000;
        int bytesInPerIteration = 4000000;
        int bytesOutPerIteration = 3000000;
        for (int i = 0; i < iterations; i++) {
            ioRatioMetric.incrementBy(bytesInPerIteration, bytesOutPerIteration);
        }
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(Math.multiplyExact((long)bytesInPerIteration, iterations));
            assertThat(value.bytesOut()).isEqualTo(Math.multiplyExact((long)bytesOutPerIteration, iterations));
        });
        assertThat(ioRatioMetric.getValue()).isEqualTo(0.75);
    }

    @Test
    public void testZeroBytesInPositiveBytesOut() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");

        ioRatioMetric.incrementBy(0, 768);
        assertThat(ioRatioMetric.getValue()).isEqualTo(Double.POSITIVE_INFINITY);
    }

    @Test
    public void testNegativeBytesIn() {
        final Logger mockLogger = Mockito.mock(Logger.class);
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name", mockLogger);
        ioRatioMetric.incrementBy(-1, 768);

        Mockito.verify(mockLogger).warn(argThat(stringContainsInOrder("cannot decrement")), eq(ioRatioMetric.getName()));
    }

    @Test
    public void testNegativeBytesOut() {
        final Logger mockLogger = Mockito.mock(Logger.class);
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name", mockLogger);
        ioRatioMetric.incrementBy(768, -1);

        Mockito.verify(mockLogger).warn(argThat(stringContainsInOrder("cannot decrement")), eq(ioRatioMetric.getName()));
    }

    @Test
    public void testZeroBytesInZeroBytesOut() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");

        ioRatioMetric.incrementBy(0, 0);
        assertThat(ioRatioMetric.getValue()).isNaN();
    }

    @Test
    public void testLongBytesInOverflow() {
        final Logger mockLogger = Mockito.mock(Logger.class);
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name", mockLogger);
        ioRatioMetric.setTo(Long.MAX_VALUE, 2L);

        assertThat(ioRatioMetric.getValue()).isEqualTo(2.168E-19);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(Long.MAX_VALUE);
            assertThat(value.bytesOut()).isEqualTo(2L);
        });

        //overflow reset
        ioRatioMetric.incrementBy(1, 10);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(4611686018427387903L + 1L);
            assertThat(value.bytesOut()).isEqualTo(1L + 10L);
        });
        Mockito.verify(mockLogger).warn(argThat(stringContainsInOrder("long overflow", "precision", "reduced")));
    }

    @Test
    public void testLongBytesOutOverflow() {
        final Logger mockLogger = Mockito.mock(Logger.class);
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name", mockLogger);
        ioRatioMetric.setTo(2L, Long.MAX_VALUE);

        assertThat(ioRatioMetric.getValue()).isEqualTo(4.612E18);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(2L);
            assertThat(value.bytesOut()).isEqualTo(Long.MAX_VALUE);
        });

        //overflow reset/truncate
        ioRatioMetric.incrementBy(10, 1);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(1L + 10L);
            assertThat(value.bytesOut()).isEqualTo(4611686018427387903L + 1L);
        });
        Mockito.verify(mockLogger).warn(argThat(stringContainsInOrder("long overflow", "precision", "reduced")));
    }

}