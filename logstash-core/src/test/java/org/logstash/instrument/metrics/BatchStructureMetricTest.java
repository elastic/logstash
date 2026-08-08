/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.instrument.metrics;

import org.HdrHistogram.Histogram;
import org.junit.Before;
import org.junit.Test;
import org.logstash.instrument.metrics.histogram.LifetimeHistogramMetric;
import org.logstash.testutils.time.ManualAdvanceClock;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.hamcrest.CoreMatchers.allOf;
import static org.hamcrest.MatcherAssert.assertThat;

public class BatchStructureMetricTest {

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

        assertThat("contains just the last 1 minute and lifetime histogram", histogramMap,
                allOf(aMapWithSize(2), hasKey("last_1_minute"), hasKey("lifetime")));

        // Check against the reference histogram
        BatchStructureMetric.HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(referenceHistogram.getValueAtPercentile(50), last1MinuteData.get50Percentile(), 0.1);
        assertEquals(referenceHistogram.getValueAtPercentile(90), last1MinuteData.get90Percentile(), 0.1);
        BatchStructureMetric.HistogramMetricData lifetimeData = histogramMap.get("lifetime");
        assertEquals(referenceHistogram.getValueAtPercentile(50), lifetimeData.get50Percentile(), 0.1);
        assertEquals(referenceHistogram.getValueAtPercentile(90), lifetimeData.get90Percentile(), 0.1);
    }

    @Test
    public void givenRunningMetricForMoreMinutesThenHistogramsHasToReflectTimeAndValues() {
        // Initial capture to establish the first histogram window
        sut.capture();

        // Record values for 4 minutes, recording low values, 80% of the time 100, 20% of the time 200
        for (int i = 0; i < 4 * 60; i++) {
            if (i % 5 < 4) {
                lifetimeHistogram.recordValue(100);
            } else {
                lifetimeHistogram.recordValue(200);
            }
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }

        // Then for 1 minute record a spike
        for (int i = 0; i < 60; i++) {
            if (i % 5 < 4) {
                lifetimeHistogram.recordValue(1000);
            } else {
                lifetimeHistogram.recordValue(1500);
            }
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }

        // Retrieve histogram values and verify values for the time windows
        Map<String, BatchStructureMetric.HistogramMetricData> histogramMap = sut.getValue();

        assertThat("contains last 1 minute, 5 minutes, and lifetime histograms", histogramMap,
                allOf(aMapWithSize(3), hasKey("last_1_minute"), hasKey("last_5_minutes"), hasKey("lifetime")));

        // Since values are uniformly distributed, we can check expected percentiles
        BatchStructureMetric.HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(1000, last1MinuteData.get50Percentile(), 10);
        assertEquals(1500, last1MinuteData.get90Percentile(), 10);
        BatchStructureMetric.HistogramMetricData last5MinutesData = histogramMap.get("last_5_minutes");
        assertEquals(100, last5MinutesData.get50Percentile(), 10);
        assertEquals(1000, last5MinutesData.get90Percentile(), 10);
        BatchStructureMetric.HistogramMetricData lifetimeData = histogramMap.get("lifetime");
        assertEquals(100, lifetimeData.get50Percentile(), 10);
        assertEquals(1000, lifetimeData.get90Percentile(), 10);
    }

    @Test
    public void givenRunningMetricWhenNoDataComesInForLastMinuteThenHistogramReflectsThisDrop() {
        // Initial capture to establish the first histogram window
        sut.capture();

        // Record values for 4 minutes, recording low values, 80% of the time 100, 20% of the time 200
        for (int i = 0; i < 4 * 60; i++) {
            if (i % 5 < 4) {
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

        assertThat("contains just last 1 minute, 5 minutes and lifetime histograms", histogramMap,
                allOf(aMapWithSize(3), hasKey("last_1_minute"), hasKey("last_5_minutes"), hasKey("lifetime")));

        // Since values are uniformly distributed, we can check expected percentiles
        BatchStructureMetric.HistogramMetricData last1MinuteData = histogramMap.get("last_1_minute");
        assertEquals(0, last1MinuteData.get50Percentile(), 10);
        assertEquals(0, last1MinuteData.get90Percentile(), 10);
        BatchStructureMetric.HistogramMetricData last5MinutesData = histogramMap.get("last_5_minutes");
        assertEquals(100, last5MinutesData.get50Percentile(), 10);
        assertEquals(200, last5MinutesData.get90Percentile(), 10);
        BatchStructureMetric.HistogramMetricData lifetimeData = histogramMap.get("lifetime");
        assertEquals(100, lifetimeData.get50Percentile(), 10);
        assertEquals(200, lifetimeData.get90Percentile(), 10);
    }

    @Test
    public void givenCaptureNeverCalledThenEstimateBatchMetricsFootprintInBytesReflectsOnlyTheBatchHistogram() {
        // no retention windows exist until capture() has been called at least once, so the estimate
        // must fall back to just the underlying batch histogram's own footprint.
        assertEquals(lifetimeHistogram.estimateBatchMetricsFootprintInBytes(), sut.estimateBatchMetricsFootprintInBytes());
    }

    @Test
    public void givenCaptureCalledThenEstimateBatchMetricsFootprintInBytesIncludesRetentionWindowContributions() {
        sut.capture();

        int withWindows = sut.estimateBatchMetricsFootprintInBytes();
        int batchHistogramAlone = lifetimeHistogram.estimateBatchMetricsFootprintInBytes();

        assertThat("once retention windows exist, they meaningfully contribute to the footprint",
                withWindows, is(greaterThan((int)(batchHistogramAlone * 1.10))));
        assertThat("but because they are packed they don't become the controlling factor",
                withWindows, is(lessThan((int)(batchHistogramAlone * 1.50))));
    }

    @Test
    public void givenValuesRecordedWithinTheSameOrderOfMagnitudeOverTimeThenEstimateBatchMetricsFootprintInBytesIsUnchanged() {
        sut.capture();
        int baseline = sut.estimateBatchMetricsFootprintInBytes();

        for (int i = 0; i < 10; i++) {
            lifetimeHistogram.recordValue(100 + i);
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }

        assertEquals("recording values that fit within the already-allocated histogram range should not grow the estimate",
                baseline, sut.estimateBatchMetricsFootprintInBytes());
    }

    @Test
    public void givenValueRecordedWithDisparateMagnitudeOverTimeThenEstimateBatchMetricsFootprintInBytesGrows() {
        sut.capture();

        for (int i = 0; i < 10; i++) {
            lifetimeHistogram.recordValue(100 + i);
            clock.advance(Duration.ofSeconds(1));
            sut.capture();
        }
        int beforeSpike = sut.estimateBatchMetricsFootprintInBytes();

        // a value several orders of magnitude larger forces the underlying histogram(s) to widen their range
        lifetimeHistogram.recordValue(1_000_000_000L);
        clock.advance(Duration.ofSeconds(1));
        sut.capture();

        int afterSpike = sut.estimateBatchMetricsFootprintInBytes();

        assertThat("a capture whose histogram had to widen its range to cover a disparate value should grow the estimate several-fold, not just marginally",
                afterSpike, is(greaterThan(beforeSpike * 5)));
        assertThat("but the growth from a single widened-range capture should still be bounded, not runaway",
                afterSpike, is(lessThan(beforeSpike * 15)));
    }

    @Test
    public void givenCardinalityGrowthWithinAnAlreadyAllocatedRangeThenRetentionWindowContributionsGrowEvenThoughTheBatchHistogramsOwnEstimateDoesNot() {
        lifetimeHistogram.recordValue(1);
        sut.capture();

        int batchHistogramFootprintBefore = lifetimeHistogram.estimateBatchMetricsFootprintInBytes();
        int totalFootprintBefore = sut.estimateBatchMetricsFootprintInBytes();

        // Recording many distinct values within the already-allocated range grows the *packed* footprint of
        // each capture's ValueHistogram (used directly by HistogramRetentionWindow#estimateMaxFootprintInBytes)
        // without growing the *unpacked* lifetime snapshot's footprint that batchHistogram's own multiplier-based
        // estimate is based on -- see LifetimeHistogramMetricTest for that half of the behavior in isolation.
        for (long value = 2; value <= 2000; value++) {
            lifetimeHistogram.recordValue(value);
        }
        clock.advance(Duration.ofSeconds(1));
        sut.capture();

        int batchHistogramFootprintAfter = lifetimeHistogram.estimateBatchMetricsFootprintInBytes();
        int totalFootprintAfter = sut.estimateBatchMetricsFootprintInBytes();

        assertThat("the batch histogram's own multiplier-based estimate should not move from cardinality growth alone",
                batchHistogramFootprintAfter, is(equalTo(batchHistogramFootprintBefore)));
        assertThat("the retention windows' real packed-footprint accounting should pick up the cardinality-driven growth several-fold, not just marginally",
                totalFootprintAfter, is(greaterThan(totalFootprintBefore * 2)));
        assertThat("but that cardinality-driven growth should still be bounded relative to the number of distinct values recorded, not runaway",
                totalFootprintAfter, is(lessThan(totalFootprintBefore * 4)));
    }

    @Test
    public void givenSuccessiveCapturesWithGrowingCardinalityThenEstimateBatchMetricsFootprintInBytesTracksTheYoungestCaptureNonDecreasingly() {
        // HistogramRetentionWindow#estimateMaxFootprintInBytes relies on the assumption that, since these are
        // cumulative lifetime histograms, the youngest capture's PackedHistogram is always the largest one in
        // the window. Verify that assumption holds -- and is reflected in the overall estimate -- across many
        // successive captures, not just a single before/after comparison.
        long value = 1;
        int previous = -1;
        int afterFirstRound = -1;
        int current = -1;
        for (int round = 0; round < 5; round++) {
            for (int i = 0; i < 500; i++) {
                lifetimeHistogram.recordValue(value++);
            }
            clock.advance(Duration.ofSeconds(1));
            sut.capture();

            current = sut.estimateBatchMetricsFootprintInBytes();
            assertTrue("the footprint estimate should never decrease as more distinct values are captured over time",
                    current >= previous);
            previous = current;
            if (round == 0) {
                afterFirstRound = current;
            }
        }

        assertThat("across several rounds of cardinality growth, the estimate should grow substantially overall, not just marginally",
                current, is(greaterThan((int)(afterFirstRound * 1.5))));
        assertThat("but that growth should still be bounded relative to the number of additional distinct values recorded, not runaway",
                current, is(lessThan((int)(afterFirstRound * 3.0))));
    }
}