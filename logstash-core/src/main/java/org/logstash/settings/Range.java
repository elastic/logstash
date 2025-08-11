package org.logstash.settings;

import org.jruby.RubyRange;
import org.jruby.runtime.ThreadContext;

public class Range<T extends Comparable<? super T>> {

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

//    public static Range<T> fromRubyRange(RubyRange r) {
//        ThreadContext context = r.getRuntime().getCurrentContext();
//        r.last(context);
//    }
}