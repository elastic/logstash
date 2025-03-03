package org.logstash.common;

import java.util.Iterator;
import java.util.NoSuchElementException;

public class CustomTokenizer {

    private final DataSplitter dataSplitter;

    static class ValueLimitIteratorDecorator implements Iterator<String> {
        private final Iterator<String> iterator;
        private final int limit = 10;

        ValueLimitIteratorDecorator(Iterator<String> iterator) {
            this.iterator = iterator;
        }

        @Override
        public boolean hasNext() {
            return iterator.hasNext();
        }

        @Override
        public String next() {
            String value = iterator.next();
            if (value.length() > limit) {
                throw new IllegalArgumentException("Too long");
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
                System.out.println("hasNext return false because next token not found");
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
            return accumulator.toString();
        }

        @Override
        public String toString() {
            return "accumulator=" + accumulator + ", currentIdx=" + currentIdx;
        }
    }

    public CustomTokenizer(String separator) {
        this.dataSplitter = new DataSplitter(separator);
    }

    public Iterable<String> extract(String data) {
        dataSplitter.append(data);

        return new Iterable<String>() {
            @Override
            public Iterator<String> iterator() {
                return new ValueLimitIteratorDecorator(dataSplitter);
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
}
