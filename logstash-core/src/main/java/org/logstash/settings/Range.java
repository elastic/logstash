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

import java.util.Objects;
import java.util.function.BiConsumer;

public class Range<T extends Integer> {

    private final T first;
    private final T last;

    public Range(T first, T last) {
        this.first = Objects.requireNonNull(first);
        this.last = Objects.requireNonNull(last);
        if (first.compareTo(last) > 0) {
            throw new IllegalArgumentException("First must be less than or equal to last");
        }
    }

    public boolean contains(Range<T> other) {
        return first.compareTo(other.first) <= 0 && last.compareTo(other.last) >= 0;
    }

    public T getFirst() {
        return first;
    }

    public T getLast() {
        return last;
    }

    public void eachWithIndex(BiConsumer<Integer, Integer> consumer) {
        // In case of a single value range, we should still yield once
        if (first.intValue() == last.intValue()) {
            consumer.accept(first.intValue(), 0);
            return;
        }
        int index = 0;
        for (int value = first.intValue(); value < last.intValue(); value++) {
            consumer.accept(value, index++);
        }
    }

    public int count() {
        return last.intValue() - first.intValue() + 1;
    }

    @Override
    public String toString() {
        return this.getClass().getName() +
                "{first=" + first +
                ", last=" + last +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Range<?> range = (Range<?>) o;
        return Objects.equals(first, range.first) && Objects.equals(last, range.last);
    }

    @Override
    public int hashCode() {
        return Objects.hash(first, last);
    }
}