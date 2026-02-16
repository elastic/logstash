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

import org.HdrHistogram.Histogram;
import org.junit.Before;
import org.junit.Test;

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
        Histogram h = sut.getValue();
        assertEquals(1, h.getTotalCount());
        assertEquals(1000L, h.getValueAtPercentile(90));
    }

    @Test
    public void givenNegativeValueRecordedThenExceptionIsRaisedWithExpectedMessage() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> sut.recordValue(-1));
        assertEquals("cannot record negative value in histogram", ex.getMessage());
    }

    @Test
    public void givenLifetimeHistogramWhenRecordingSecondLargerValueThenP90IncreasesAndPreviousP90MovesToLowerPercentile() {
        sut.recordValue(100);
        Histogram afterFirst = sut.getValue();
        long p90AfterFirst = afterFirst.getValueAtPercentile(90);
        assertEquals(100L, p90AfterFirst);

        sut.recordValue(1000);
        Histogram afterSecond = sut.getValue();
        long p90AfterSecond = afterSecond.getValueAtPercentile(90);
        assertTrue("90th percentile should increase after recording a larger value", p90AfterSecond > p90AfterFirst);
        assertEquals(1000L, p90AfterSecond);

        long p50AfterSecond = afterSecond.getValueAtPercentile(50);
        assertEquals("previous 90th percentile value (100) should now be at 50th percentile", 100L, p50AfterSecond);
    }
}