package org.logstash.ackedqueue;

import java.util.Iterator;
import java.util.NoSuchElementException;

public class BatchedIterator<T> implements Iterator<T> {
    private Iterator<T> delegate;
    private int limit;
    private int iterated;

    // @param delegate the original iterator to batch
    // @param limit the bach size or the maximum number or elements to iterator over
    public BatchedIterator(Iterator<T> delegate, int limit) {
        this.delegate = delegate;
        this.limit = limit;
    }


    public boolean hasNext() {
        if (iterated < limit) {
            return delegate.hasNext();
        }
        return false;
    }

    public T next() {
        if (iterated >= limit) {
            throw new NoSuchElementException();
        }

        iterated++;
        return delegate.next();
    }
}