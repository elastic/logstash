package org.logstash.instrument.metrics;

import org.HdrHistogram.Histogram;
import org.junit.Before;
import org.junit.Test;
import org.logstash.instrument.metrics.histogram.LifetimeHistogramMetric;
import org.logstash.testutils.time.ManualAdvanceClock;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.hamcrest.CoreMatchers.allOf;
import static org.hamcrest.Matchers.aMapWithSize;
import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.MatcherAssert.assertThat;

public class BatchStructureMetricTest {

    private final SecureRandom random = new SecureRandom();

    private ManualAdvanceClock clock;
    private LifetimeHistogramMetric lifetimeHistogram;
    private BatchStructureMetric sut;

    @Before
    public void setUp() {
        clock = new ManualAdvanceClock(Instant.now());
        lifetimeHistogram = new LifetimeHistogramMetric("test_histogram");
        sut = new BatchStructureMetric("batch_structure", lifetimeHistogram, clock::nanoTime);
    }

    @Test
    public void givenMostlyStaticValues_whenRecordingValues_thenHistogramsReflectThis() {
        Histogram referenceHistogram = new Histogram(1_000_000, 3);
        // Initial capture to establish the first histogram window
        sut.capture();

        // Record values for 60 seconds
        for (int i = 0; i < 45; i++) {
            lifetimeHistogram.recordValue(100);
            referenceHistogram.recordValue(100);
        }

        for (int i = 0; i < 15; i++) {
            lifetimeHistogram.recordValue(200);
            referenceHistogram.recordValue(200);
        }
        // simulate passage of time to ensure the first capture is outside the 1 minute window
        clock.advance(Duration.ofSeconds(60));

        // Retrieve histogram values, getValue takes another capture and computes the diff with the initial empty capture
        Map<String, BatchStructureMetric.HistogramMetricData> histogramMap = sut.getValue();
        System.out.println(histogramMap);

        assertThat("contains just the last 1 minute histogram", histogramMap,
                allOf(aMapWithSize(1), hasKey("last_1_minute")));

        // Check against the reference histogram
        BatchStructureMetric.HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(referenceHistogram.getValueAtPercentile(50), last1MinuteData.get50Percentile(), 0.1);
        assertEquals(referenceHistogram.getValueAtPercentile(90), last1MinuteData.get90Percentile(), 0.1);
    }

    @Test
    public void givenRunningMetricForMoreMinutesThenHistogramsHasToReflectTimeAndValues() {
        // Initial capture to establish the first histogram window
        sut.capture();

        // Record values for 4 minutes, recording low values, 80% of the time 100, 20% of the time 200
        for (int i = 0; i < 4 * 60; i++) {
            if (random.nextInt(100) < 80) {
                lifetimeHistogram.recordValue(100);
            } else {
                lifetimeHistogram.recordValue(200);
            }
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }

        // Then for 1 minute record a spike
        for (int i = 0; i < 60; i++) {
            if (random.nextInt(100) < 80) {
                lifetimeHistogram.recordValue(1000);
            } else {
                lifetimeHistogram.recordValue(1500);
            }
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }

        // Retrieve histogram values and verify values for the time windows
        Map<String, BatchStructureMetric.HistogramMetricData> histogramMap = sut.getValue();

        assertThat("contains just last 1 minute and 5 minutes histograms", histogramMap,
                allOf(aMapWithSize(2), hasKey("last_1_minute"), hasKey("last_5_minutes")));

        // Since values are uniformly distributed, we can check expected percentiles
        BatchStructureMetric.HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(1000, last1MinuteData.get50Percentile(), 10);
        assertEquals(1500, last1MinuteData.get90Percentile(), 10);
        BatchStructureMetric.HistogramMetricData last5MinutesData = histogramMap.get("last_5_minutes");
        assertEquals(100, last5MinutesData.get50Percentile(), 10);
        assertEquals(1000, last5MinutesData.get90Percentile(), 10);
    }

    @Test
    public void givenRunningMetricWhenNoDataComesInForLastMinuteThenHistogramReflectsThisDrop() {
        // Initial capture to establish the first histogram window
        sut.capture();

        // Record values for 4 minutes, recording low values, 80% of the time 100, 20% of the time 200
        for (int i = 0; i < 4 * 60; i++) {
            if (random.nextInt(100) < 80) {
                lifetimeHistogram.recordValue(100);
            } else {
                lifetimeHistogram.recordValue(200);
            }
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }

        // Then for 1 minute record no values at all
        clock.advance(Duration.ofSeconds(60));

        // take another capture and move time little bit forward to have the last capture outside of the 1 minute window,
        // otherwise the capture taken in getValue will be the only one in the window and we would still have values
        // in the histogram, which could be some tail snapshots from the 4 minutes of captures.
        sut.capture();
        clock.advance(Duration.ofSeconds(1));

        // Retrieve histogram values and verify values for the time windows
        Map<String, BatchStructureMetric.HistogramMetricData> histogramMap = sut.getValue();

        assertThat("contains just last 1 minute and 5 minutes histograms", histogramMap,
                allOf(aMapWithSize(2), hasKey("last_1_minute"), hasKey("last_5_minutes")));

        // Since values are uniformly distributed, we can check expected percentiles
        BatchStructureMetric.HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(0, last1MinuteData.get50Percentile(), 10);
        assertEquals(0, last1MinuteData.get90Percentile(), 10);
        BatchStructureMetric.HistogramMetricData last5MinutesData = histogramMap.get("last_5_minutes");
        assertEquals(100, last5MinutesData.get50Percentile(), 10);
        assertEquals(200, last5MinutesData.get90Percentile(), 10);
    }
}