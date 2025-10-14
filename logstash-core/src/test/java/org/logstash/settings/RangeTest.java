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

package org.logstash.settings;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class RangeTest {

    int count = 0;

    @Before
    public void setUp() {
        count = 0;
    }

    @Test
    public void givenRangeCompletelyOverlappingAnotherThenContainsReturnTrue() {
        Range<Integer> container = new Range<>(5, 10);
        Range<Integer> contained = new Range<>(6, 9);
        assertTrue(container.contains(contained));
        assertFalse(contained.contains(container));
    }

    @Test
    public void givenRangePartiallyOverlappingAnotherThenContainsReturnFalse() {
        Range<Integer> container = new Range<>(5, 10);
        Range<Integer> left = new Range<>(3, 6);
        Range<Integer> right = new Range<>(7, 11);
        assertFalse(container.contains(left));
        assertFalse(container.contains(right));
    }

    @Test
    public void givenRangeWithSameBoundsThenCountReturnOne() {
        Range<Integer> singlePointRange = new Range<>(5, 5);
        assertEquals(1, singlePointRange.count());
    }

    @Test
    public void givenRangeWithDifferentBoundsThenCountReturnCorrectValue() {
        Range<Integer> range = new Range<>(5, 10);
        assertEquals(6, range.count());
    }

    @Test
    public void givenRangeWhenIteratorIsInvokedCorrectNumberOfTimes() {
        // start bound inclusive, end bound exclusive
        Range<Integer> range = new Range<>(5, 10);
        range.eachWithIndex((value, index) -> count++);
        assertEquals(5, count);
    }

    @Test
    public void givenRangeWithSameBoundsWhenIteratorIsInvokedJustOneTime() {
        Range<Integer> singlePointRange = new Range<>(5, 5);
        singlePointRange.eachWithIndex((value, index) -> count++);
        assertEquals(1, singlePointRange.count());
    }

    @Test(expected = IllegalArgumentException.class)
    public void givenRangeWithFirstGreaterThanLastThenThrowIllegalArgumentException() {
        new Range<>(10, 5);
    }
}