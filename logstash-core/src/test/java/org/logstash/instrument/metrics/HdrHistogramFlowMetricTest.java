package org.logstash.instrument.metrics;

import org.HdrHistogram.Histogram;
import org.junit.Before;
import org.junit.Test;
import org.logstash.testutils.time.ManualAdvanceClock;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import static org.hamcrest.Matchers.aMapWithSize;
import static org.hamcrest.Matchers.hasKey;
import static org.junit.Assert.*;
import static org.hamcrest.CoreMatchers.*;
import static org.hamcrest.MatcherAssert.assertThat;

public class HdrHistogramFlowMetricTest {

    private final SecureRandom random = new SecureRandom();

    private ManualAdvanceClock clock;
    private HdrHistogramFlowMetric sut;

    @Before
    public void setUp() {
        clock = new ManualAdvanceClock(Instant.now());
        sut = new HdrHistogramFlowMetric("histogram", clock::nanoTime);
    }

    @Test
    public void givenMostlyStaticValues_whenRecordingValues_thenHistogramsReflectThis() {
        Histogram referenceHistogram = new Histogram(1_000_000, 3);

        // Record values for 60 seconds
        for(int i = 0; i < 45; i++) {
            sut.recordValue(100);
            referenceHistogram.recordValue(100);
            clock.advance(Duration.ofSeconds(1));
        }
        for(int i = 0; i < 15; i++) {
            sut.recordValue(200);
            referenceHistogram.recordValue(200);
            clock.advance(Duration.ofSeconds(1));
        }

        System.out.println("Sample Histogram Percentiles:");
        printPercentiles(referenceHistogram);

        // Retrieve histogram values
        Map<String, HistogramMetricData> histogramMap = sut.getValue();
        System.out.println(histogramMap);

        assertThat("contains just the last 1 minute histogram", histogramMap,
                allOf(aMapWithSize(1), hasKey("last_1_minute")));

        // Check against the reference histogram
        HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(referenceHistogram.getValueAtPercentile(75), last1MinuteData.get75Percentile(), 0.1);
        assertEquals(referenceHistogram.getValueAtPercentile(90), last1MinuteData.get90Percentile(), 0.1);
    }


    @Test
    public void givenRunningMetricForMoreMinutesThenHistogramsHasToReflectTimeAndValues() {
        // Record values for 4 minutes, recording low values, 80% of the time 100, 20% of the time 200
        for(int i = 0; i < 4 * 60; i++) {
            if (random.nextInt(100) < 80) {
                sut.recordValue(100);
            } else {
                sut.recordValue(200);
            }
            clock.advance(Duration.ofSeconds(1));
        }

        // Then for 1 minute record a spike
        for(int i = 0; i < 60; i++) {
            if (random.nextInt(100) < 80) {
                sut.recordValue(1000);
            } else {
                sut.recordValue(1500);
            }
            clock.advance(Duration.ofSeconds(1));
        }

        // Retrieve histogram values and verify values for the time windows
        Map<String, HistogramMetricData> histogramMap = sut.getValue();
        System.out.println(histogramMap);

        assertThat("contains just last 1 minute and 5 minutes histograms", histogramMap,
                allOf(aMapWithSize(2), hasKey("last_1_minute"), hasKey("last_5_minutes")));

        // Since values are uniformly distributed, we can check expected percentiles
        HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(1000, last1MinuteData.get75Percentile(), 10);
        assertEquals(1500, last1MinuteData.get90Percentile(), 10);
        HistogramMetricData last5MinutesData = histogramMap.get("last_5_minutes");
        assertEquals(200, last5MinutesData.get75Percentile(), 10);
        assertEquals(1000, last5MinutesData.get90Percentile(), 10);
    }

    @Test
    public void givenRunningMetricWhenNoDataComesInForLastMinuteThenHistogramReflectsThisDrop() {
        // Record values for 4 minutes, recording low values, 80% of the time 100, 20% of the time 200
        for(int i = 0; i < 4 * 60; i++) {
            if (random.nextInt(100) < 80) {
                sut.recordValue(100);
            } else {
                sut.recordValue(200);
            }
            clock.advance(Duration.ofSeconds(1));
        }
        
        // Then for 1 minute record no values at all
        clock.advance(Duration.ofSeconds(60));

        // Retrieve histogram values and verify values for the time windows
        Map<String, HistogramMetricData> histogramMap = sut.getValue();
        System.out.println(histogramMap);

        assertThat("contains just last 1 minute and 5 minutes histograms", histogramMap,
                allOf(aMapWithSize(2), hasKey("last_1_minute"), hasKey("last_5_minutes")));

        // Since values are uniformly distributed, we can check expected percentiles
        HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(0, last1MinuteData.get75Percentile(), 10);
        assertEquals(0, last1MinuteData.get90Percentile(), 10);
        HistogramMetricData last5MinutesData = histogramMap.get("last_5_minutes");
        assertEquals(100, last5MinutesData.get75Percentile(), 10);
        assertEquals(200, last5MinutesData.get90Percentile(), 10);
    }


    private static void printPercentiles(Histogram sampleHistogram) {
        System.out.println("P50: " + sampleHistogram.getValueAtPercentile(50));
        System.out.println("P75: " + sampleHistogram.getValueAtPercentile(75));
        System.out.println("P90: " + sampleHistogram.getValueAtPercentile(90));
        System.out.println("P95: " + sampleHistogram.getValueAtPercentile(95));
        System.out.println("P99: " + sampleHistogram.getValueAtPercentile(99));
    }

    @Test
    public void testPlainHistogramVsSnapshots() {
        Histogram histogram1 = new Histogram(1_000_000, 3);
        for (int i=0; i < 20; i++) {
            histogram1.recordValue(100);
        }
        Histogram histogram2 = new Histogram(1_000_000, 3);
        for (int i=0; i < 2; i++) {
            histogram2.recordValue(200);
        }

        Histogram aggregatedHistogram = new Histogram(1_000_000, 3);
        aggregatedHistogram.add(histogram1);
        aggregatedHistogram.add(histogram2);

        printPercentiles(aggregatedHistogram);
    }
}