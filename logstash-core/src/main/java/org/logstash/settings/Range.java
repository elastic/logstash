package org.logstash.settings;

import java.util.Objects;
import java.util.function.BiConsumer;

public class Range<T extends Integer> {

    private final T first;
    private final T last;

    public Range(T first, T last) {
        this.first = first;
        this.last = last;
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

    // TODO cover with tests
    public void eachWithIndex(BiConsumer<Integer, Integer> consumer) {
        // In case of a single value range, we should still yield once
        if (first.intValue() == last.intValue()) {
            consumer.accept(first.intValue(), 0);
            return;
        }
        int index = 0;
        for (int value = first.intValue(); first.intValue() < last.intValue(); value++) {
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