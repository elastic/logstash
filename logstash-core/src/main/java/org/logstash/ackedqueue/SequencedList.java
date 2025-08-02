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


package org.logstash.ackedqueue;

import java.util.ArrayList;
import java.util.List;

/**
 * Carries sequence numbers and items read from queue.
 * */
public class SequencedList<E> {
    private final List<E> elements;
    private final long minSeqNum;

    public SequencedList(List<E> elements, long minSeqNum) {
        this.elements = elements;
        this.minSeqNum = minSeqNum;
    }

    public List<E> getElements() {
        return elements;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public List<Entry<E>> entries() {
        List<Entry<E>> entries = new ArrayList<>(elements.size());
        for (int i = 0; i < elements.size(); i++) {
            entries.add(new Entry<>(elements.get(i), this.minSeqNum + i));
        }
        return entries;
    }

    public static class Entry<E> {
        public final E element;
        public final long seqNum;
        public Entry(E element, long seqNum) {
            this.element = element;
            this.seqNum = seqNum;
        }
    }
}
