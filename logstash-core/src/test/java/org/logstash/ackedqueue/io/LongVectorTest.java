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


package org.logstash.ackedqueue.io;

import org.junit.Test;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class LongVectorTest {

    @Test
    public void storesAndResizes() {
        final int count = 10_000;
        final LongVector vector = new LongVector(1000);
        for (long i = 0L; i < count; ++i) {
            vector.add(i);
        }
        assertThat(vector.size(), is(count));
        for (int i = 0; i < count; ++i) {
            assertThat((long) i, is(vector.get(i)));
        }
    }

    @Test
    public void storesVectorAndResizes() {
        final int count = 1000;
        final LongVector vector1 = new LongVector(count);
        for (long i = 0L; i < count; ++i) {
            vector1.add(i);
        }
        final LongVector vector2 = new LongVector(count);
        for (long i = 0L + count; i < 2 * count; ++i) {
            vector2.add(i);
        }
        vector1.add(vector2);
        assertThat(vector1.size(), is(2 * count));
        for (int i = 0; i < 2 * count; ++i) {
            assertThat((long) i, is(vector1.get(i)));
        }
    }
}
