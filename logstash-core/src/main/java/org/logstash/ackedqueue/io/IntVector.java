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

final class IntVector {

    private int count;

    private int[] data;

    IntVector() {
        data = new int[1024];
        count = 0;
    }

    /**
     * Store the {@code int} to the underlying {@code int[]}, resizing it if necessary.
     * @param num Int to store
     */
    public void add(final int num) {
        if (data.length < count + 1) {
            final int[] old = data;
            data = new int[data.length << 1];
            System.arraycopy(old, 0, data, 0, old.length);
        }
        data[count++] = num;
    }

    /**
     * Get value stored at given index.
     * @param index Array index (only values < {@link IntVector#count} are valid)
     * @return Int
     */
    public int get(final int index) {
        return data[index];
    }

    /**
     * @return Number of elements stored in this instance
     */
    public int size() {
        return count;
    }
}
