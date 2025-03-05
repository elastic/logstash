package org.logstash.common;

import java.util.Iterator;
import java.util.NoSuchElementException;

public class BufferedTokenizer {

    private final DataSplitter dataSplitter;
    private final Iterable<String> iterable;
    private Integer sizeLimit;

    static abstract class IteratorDecorator<T> implements Iterator<T> {
        protected final Iterator<String> iterator;

        IteratorDecorator(Iterator<String> iterator) {
            this.iterator = iterator;
        }

        @Override
        public boolean hasNext() {
            return iterator.hasNext();
        }
    }

    static class ValueLimitIteratorDecorator extends IteratorDecorator<String> {
        private final int limit;

        ValueLimitIteratorDecorator(Iterator<String> iterator, int sizeLimit) {
            super(iterator);
            this.limit = sizeLimit;
        }

        @Override
        public String next() {
            String value = iterator.next();
            if (value.length() > limit) {
                throw new IllegalStateException("input buffer full, consumed token which exceeded the sizeLimit " + limit);
            }
            return value;
        }
    }

    static class DataSplitter implements Iterator<String> {
        private final String separator;
        private int currentIdx = 0;
        private final StringBuilder accumulator = new StringBuilder();

        DataSplitter(String separator) {
            this.separator = separator;
        }

        @Override
        public boolean hasNext() {
            int nextIdx = accumulator.indexOf(separator, currentIdx);
            if (nextIdx == -1) {
                // not found next separator
                cleanupAccumulator();
                return false;
            } else {
                return true;
            }
        }

        @Override
        public String next() {
            int nextIdx = accumulator.indexOf(separator, currentIdx);
            if (nextIdx == -1) {
                // not found next separator
                cleanupAccumulator();
                throw new NoSuchElementException();
            } else {
                String token = accumulator.substring(currentIdx, nextIdx);
                currentIdx = nextIdx + separator.length();
                return token;
            }
        }

        private void cleanupAccumulator() {
            accumulator.delete(0, currentIdx);
            currentIdx = 0;
        }

        public void append(String data) {
            accumulator.append(data);
        }

        public String flush() {
            return accumulator.substring(currentIdx);
        }

        @Override
        public String toString() {
            return "accumulator=" + accumulator + ", currentIdx=" + currentIdx;
        }
    }

    public BufferedTokenizer() {
        this("\n");
    }

    public BufferedTokenizer(String separator) {
        this.dataSplitter = new DataSplitter(separator);
        this.iterable = setupIterable();
    }

    public BufferedTokenizer(String separator, int sizeLimit) {
        if (sizeLimit <= 0) {
            throw new IllegalArgumentException("Size limit must be positive");
        }

        this.dataSplitter = new DataSplitter(separator);
        this.sizeLimit = sizeLimit;
        this.iterable = setupIterable();
    }

    public Iterable<String> extract(String data) {
        dataSplitter.append(data);

        return iterable;
    }

    private Iterable<String> setupIterable() {
        return new Iterable<String>() {
            @Override
            public Iterator<String> iterator() {
                Iterator<String> returnedIterator = dataSplitter;
                if (sizeLimit != null) {
                    returnedIterator = new ValueLimitIteratorDecorator(returnedIterator, sizeLimit);
                }
                return returnedIterator;
            }
        };
    }

    public String flush() {
        return dataSplitter.flush();
    }

    @Override
    public String toString() {
        return dataSplitter.toString();
    }

    public boolean isEmpty() {
        return !dataSplitter.hasNext();
    }
}
