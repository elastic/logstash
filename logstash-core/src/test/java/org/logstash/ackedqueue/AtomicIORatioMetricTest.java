package org.logstash.ackedqueue;

import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

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
        long bytesInPerIteration = 4000000;
        long bytesOutPerIteration = 3000000;
        for (int i = 0; i < iterations; i++) {
            ioRatioMetric.incrementBy(bytesInPerIteration, bytesOutPerIteration);
        }
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(bytesInPerIteration * iterations);
            assertThat(value.bytesOut()).isEqualTo(bytesOutPerIteration * iterations);
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
    public void testZeroBytesInNegativeBytesOut() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");

        ioRatioMetric.incrementBy(0, -768);
        assertThat(ioRatioMetric.getValue()).isEqualTo(Double.NEGATIVE_INFINITY);
    }

    @Test
    public void testZeroBytesInZeroBytesOut() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");

        ioRatioMetric.incrementBy(0, 0);
        assertThat(ioRatioMetric.getValue()).isNaN();
    }

    @Test
    public void testLongBytesInOverflow() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");
        ioRatioMetric.incrementBy(Long.MAX_VALUE, 1L);

        assertThat(ioRatioMetric.getValue()).isEqualTo(1.084E-19);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(Long.MAX_VALUE);
            assertThat(value.bytesOut()).isEqualTo(1L);
        });

        //overflow reset
        ioRatioMetric.incrementBy(1L, 10L);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(1L);
            assertThat(value.bytesOut()).isEqualTo(10L);
        });
    }

    @Test
    public void testLongBytesOutOverflow() {
        final AtomicIORatioMetric ioRatioMetric = new AtomicIORatioMetric("name");
        ioRatioMetric.incrementBy(1L, Long.MAX_VALUE);

        assertThat(ioRatioMetric.getValue()).isEqualTo(9.223E18);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(1L);
            assertThat(value.bytesOut()).isEqualTo(Long.MAX_VALUE);
        });

        //overflow reset
        ioRatioMetric.incrementBy(10L, 1L);
        assertThat(ioRatioMetric.getLifetime()).satisfies(value -> {
            assertThat(value.bytesIn()).isEqualTo(10L);
            assertThat(value.bytesOut()).isEqualTo(1L);
        });
    }

}