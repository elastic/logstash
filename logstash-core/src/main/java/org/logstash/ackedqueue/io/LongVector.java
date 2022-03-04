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

/**
 * Internal class used in persistent queue implementation.
 *
 * It'a vector that stores primitives long (no autoboxing) expanding, by copy, the underling array when
 * more space is needed.
 * */
public final class LongVector {

    private int count;

    private long[] data;

    public LongVector(final int size) {
        data = new long[size];
        count = 0;
    }

    /**
     * Store the {@code long} to the underlying {@code long[]}, resizing it if necessary.
     * @param num Long to store
     */
    public void add(final long num) {
        if (data.length < count + 1) {
            final long[] old = data;
            data = new long[(data.length << 1) + 1];
            System.arraycopy(old, 0, data, 0, old.length);
        }
        data[count++] = num;
    }

    /**
     * Store the {@code long[]} to the underlying {@code long[]}, resizing it if necessary.
     * @param nums {@code long[]} to store
     */
    public void add(final LongVector nums) {
        if (data.length < count + nums.size()) {
            final long[] old = data;
            data = new long[(data.length << 1) + nums.size()];
            System.arraycopy(old, 0, data, 0, old.length);
        }
        for (int i = 0; i < nums.size(); i++) {
            data[count + i] = nums.get(i);
        }
        count += nums.size();
    }

    /**
     * Get value stored at given index.
     * @param index Array index (only values smaller than {@link LongVector#count} are valid)
     * @return Int
     */
    public long get(final int index) {
        return data[index];
    }

    /**
     * @return Number of elements stored in this instance
     */
    public int size() {
        return count;
    }
}
