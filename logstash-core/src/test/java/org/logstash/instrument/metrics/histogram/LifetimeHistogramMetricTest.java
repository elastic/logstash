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

package org.logstash.instrument.metrics.histogram;

import org.junit.Before;
import org.junit.Test;
import org.logstash.instrument.metrics.histogram.LifetimeHistogramMetric.ValueHistogram;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;

public class LifetimeHistogramMetricTest {

    private LifetimeHistogramMetric sut;

    @Before
    public void setUp() {
        sut = new LifetimeHistogramMetric("test_histogram");
    }

    @Test
    public void givenValueRecordedThen90thPercentileFromGetValueReflectsIt() {
        sut.recordValue(1000);
        ValueHistogram h = sut.getValue();
        assertEquals(1, h.getTotalCount());
        assertEquals(1000L, h.getValueAtPercentile(90));
        assertEquals(1000L, h.getMaxValue());
    }

    @Test
    public void givenNegativeValueRecordedThenExceptionIsRaisedWithExpectedMessage() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> sut.recordValue(-1));
        assertEquals("cannot record negative value in histogram", ex.getMessage());
    }

    @Test
    public void givenLifetimeHistogramWhenRecordingSecondLargerValueThenP90IncreasesAndPreviousP90MovesToLowerPercentile() {
        sut.recordValue(100);
        ValueHistogram afterFirst = sut.getValue();
        long p90AfterFirst = afterFirst.getValueAtPercentile(90);
        assertEquals(100L, p90AfterFirst);
        assertEquals(100L, afterFirst.getMaxValue());

        sut.recordValue(1000);
        ValueHistogram afterSecond = sut.getValue();
        long p90AfterSecond = afterSecond.getValueAtPercentile(90);
        assertTrue("90th percentile should increase after recording a larger value", p90AfterSecond > p90AfterFirst);
        assertEquals(1000L, p90AfterSecond);
        assertEquals(1000L, afterSecond.getMaxValue());

        long p50AfterSecond = afterSecond.getValueAtPercentile(50);
        assertEquals("previous 90th percentile value (100) should now be at 50th percentile", 100L, p50AfterSecond);
    }

    @Test
    public void givenValuesRecordedThenGetMaxValueReturnsLargestRecordedValue() {
        sut.recordValue(100);
        sut.recordValue(1000);
        ValueHistogram h = sut.getValue();
        assertEquals(1000L, h.getMaxValue());
    }

    @Test
    public void baselineFootprintBallpark() {
        // anchor the current size to prevent unseen drift
        int expectedFootprintEstimate = 100_000;
        int expectedFootprintTolerance =  5_000;

        int footprint = sut.estimateBatchMetricsFootprintInBytes();

        assertThat("footprint doesnt' drift far from the baseline from one release to the next",
                footprint, both(greaterThanOrEqualTo(expectedFootprintEstimate - expectedFootprintTolerance))
                           .and(lessThanOrEqualTo(expectedFootprintEstimate + expectedFootprintTolerance)));
    }

    @Test
    public void givenNoValuesRecordedThenEstimateBatchMetricsFootprintInBytesIsPositiveAndStableAcrossCalls() {
        int first = sut.estimateBatchMetricsFootprintInBytes();
        assertThat("footprint estimate should be positive even for an empty histogram",
                first, is(greaterThanOrEqualTo(0)));

        int second = sut.estimateBatchMetricsFootprintInBytes();
        assertThat("repeated calls without new recordings should not change the estimate",
                second, is(equalTo(first)));
    }

    @Test
    public void givenValueRecordedWithoutEverCallingGetValueThenEstimateBatchMetricsFootprintInBytesStillReflectsIt() {
        // the estimate must sync from the recorder itself; it cannot rely on getValue() having been called.
        LifetimeHistogramMetric narrow = new LifetimeHistogramMetric("narrow");
        int beforeRecording = narrow.estimateBatchMetricsFootprintInBytes();

        narrow.recordValue(100_000_000_000L);
        int afterRecording = narrow.estimateBatchMetricsFootprintInBytes();

        assertThat("recording a value needing a much wider range should grow the footprint estimate several-fold, not just marginally",
                afterRecording, is(greaterThan(beforeRecording * 10)));
        assertThat("the footprint estimate should not balloon disproportionately to the widened range either",
                afterRecording, is(lessThan(beforeRecording * 15)));
    }

    @Test
    public void givenManyValuesRecordedWithinTheSameOrderOfMagnitudeThenEstimateBatchMetricsFootprintInBytesIsUnchanged() {
        int before = sut.estimateBatchMetricsFootprintInBytes();

        for (long value = 100; value < 200; value++) {
            sut.recordValue(value);
        }

        assertEquals("values that fit within the already-allocated range should not grow the footprint",
                before, sut.estimateBatchMetricsFootprintInBytes());
    }

    @Test
    public void givenManyValuesRecordedWithDisparateMagnitudesThenEstimateBatchMetricsFootprintInBytesGrowsToCoverTheirRange() {
        int beforeRecording = sut.estimateBatchMetricsFootprintInBytes();

        long[] disparateValues = {1L, 100L, 10_000L, 1_000_000L, 100_000_000L, 1_000_000_000L};
        for (long value : disparateValues) {
            sut.recordValue(value);
        }

        int afterRecording = sut.estimateBatchMetricsFootprintInBytes();
        assertThat("recording values spanning several orders of magnitude should grow the footprint estimate several-fold, not just marginally",
                afterRecording, is(greaterThan(beforeRecording * 8)));
        assertThat("the footprint estimate should not balloon disproportionately to the widened range either",
                afterRecording, is(lessThan(beforeRecording * 16)));


        // once the underlying histogram has been resized to accommodate the recorded range, the
        // estimate should be stable, whether or not additional values are recorded within that range.
        sut.recordValue(500_000L);
        assertEquals("recording additional values already within the accommodated range should not grow the footprint further",
                afterRecording, sut.estimateBatchMetricsFootprintInBytes());
    }

    @Test
    public void givenManyDistinctValuesRecordedWithinANarrowRangeThenPackedCaptureFootprintGrowsWhileTheMetricsOwnEstimateStaysConservativelyAboveIt() {
        // A single value establishes the histogram's structure without populating many distinct buckets.
        sut.recordValue(1);
        int estimateBeforeCardinalityGrowth = sut.estimateBatchMetricsFootprintInBytes();
        int packedFootprintBeforeCardinalityGrowth = sut.getValue().getEstimatedFootprintInBytes();

        // Recording many distinct values within that same narrow range grows the *packed* representation
        // that ValueHistogram (and therefore every capture) actually uses, since it now must track many
        // more distinct non-zero buckets -- but it does NOT require the *unpacked* lifetime snapshot that
        // estimateBatchMetricsFootprintInBytes() is based on to widen its range/structure, since all of
        // these values already fit within the range established above.
        for (long value = 2; value <= 2000; value++) {
            sut.recordValue(value);
        }

        int estimateAfterCardinalityGrowth = sut.estimateBatchMetricsFootprintInBytes();
        int packedFootprintAfterCardinalityGrowth = sut.getValue().getEstimatedFootprintInBytes();

        assertEquals("recording many distinct values within the already-allocated range should not move the metric's own footprint estimate",
                estimateBeforeCardinalityGrowth, estimateAfterCardinalityGrowth);
        assertThat("the packed capture footprint should grow substantially as distinct populated buckets increase",
                packedFootprintAfterCardinalityGrowth, is(greaterThan(packedFootprintBeforeCardinalityGrowth * 5)));
        assertThat("but the packed capture footprint's growth should still be bounded relative to the cardinality increase, not runaway",
                packedFootprintAfterCardinalityGrowth, is(lessThan( packedFootprintBeforeCardinalityGrowth * 20)));


        // This is the crux of the "conservatively high" estimate: even though cardinality growth drove the
        // real (packed) capture footprint up substantially without moving the metric's own dense-histogram-based
        // estimate at all, the multiplication factor applied in estimateBatchMetricsFootprintInBytes() must still
        // keep the estimate at or above what a real capture actually needs.
        assertThat("the metric's conservative estimate must remain >= the actual packed capture footprint",
                estimateAfterCardinalityGrowth, is(greaterThanOrEqualTo(packedFootprintAfterCardinalityGrowth)));
    }
}