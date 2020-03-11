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


package org.logstash.instrument.metrics.counter;

import org.junit.Before;
import org.junit.Test;
import org.logstash.instrument.metrics.MetricType;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link LongCounter}
 */
public class LongCounterTest {

    private final long INITIAL_VALUE = 0l;
    private LongCounter longCounter;

    @Before
    public void _setup() {
        longCounter = new LongCounter("bar");
    }

    @Test
    public void getValue() {
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE);
    }

    @Test
    public void increment() {
        longCounter.increment();
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE + 1);
    }

    @Test(expected = IllegalArgumentException.class)
    public void incrementByNegativeValue() {
        longCounter.increment(-100l);
    }

    @Test(expected = IllegalArgumentException.class)
    public void incrementByNegativeLongValue() {
        longCounter.increment(Long.valueOf(-100));
    }

    @Test
    public void incrementByValue() {
        longCounter.increment(100l);
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE + 100);
        longCounter.increment(Long.valueOf(100));
        assertThat(longCounter.getValue()).isEqualTo(INITIAL_VALUE + 200);
    }

    @Test
    public void noInitialValue() {
        LongCounter counter = new LongCounter("bar");
        counter.increment();
        assertThat(counter.getValue()).isEqualTo(1l);
    }

    @Test
    @SuppressWarnings("deprecation")
    public void type() {
        assertThat(longCounter.type()).isEqualTo(MetricType.COUNTER_LONG.asString());
    }
}
