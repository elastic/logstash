/*
 * Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
 * or more contributor license agreements. See the NOTICE file distributed with
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
        private int nextSeparatorIdx = -1;
        private final StringBuilder accumulator = new StringBuilder();

        DataSplitter(String separator) {
            this.separator = separator;
        }

        @Override
        public synchronized boolean hasNext() {
            return matchNextSeparatorIdx();
        }

        @Override
        public synchronized String next() {
            if (!matchNextSeparatorIdx()) {
                throw new NoSuchElementException();
            }

            String token = accumulator.substring(currentIdx, nextSeparatorIdx);
            currentIdx = nextSeparatorIdx + separator.length();
            nextSeparatorIdx = -1;
            return token;
        }

        /**
         * Used to retrieve the index of the next token just one time. It saves into the nextSeparatorIdx
         * and return true if a next token is present.
         * Updates internal state for tracking.
         *
         * @return true iff a next complete token is available.
         */
        private boolean matchNextSeparatorIdx() {
            if (nextSeparatorIdx == -1) {
                nextSeparatorIdx = accumulator.indexOf(separator, currentIdx);
            }
            // clean up accumulator if no next separator found
            if (nextSeparatorIdx == -1 && currentIdx > 0) {
                cleanupAccumulator();
            }
            return nextSeparatorIdx != -1;
        }

        private void cleanupAccumulator() {
            accumulator.delete(0, currentIdx);
            currentIdx = 0;
        }

        public void append(String data) {
            accumulator.append(data);
        }

        public String flush() {
            final String flushed = accumulator.substring(currentIdx);
            // empty the accumulator
            accumulator.setLength(0);
            currentIdx = 0;
            return flushed;
        }

        // considered empty if caught up to the accumulator
        public synchronized boolean isBufferEmpty() {
            return currentIdx >= accumulator.length();
        }

        @Override
        public synchronized String toString() {
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
        return () -> {
            Iterator<String> returnedIterator = dataSplitter;
            if (sizeLimit != null) {
                returnedIterator = new ValueLimitIteratorDecorator(returnedIterator, sizeLimit);
            }
            return returnedIterator;
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
//        return !dataSplitter.hasNext();
        return dataSplitter.isBufferEmpty();
    }
}
