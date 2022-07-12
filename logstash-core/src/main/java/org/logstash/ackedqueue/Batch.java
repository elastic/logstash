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

import java.io.Closeable;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Container for a set of events from queue to be processed by filters/outputs.
 * */
public class Batch implements Closeable {

    private final List<Queueable> elements;

    private final long firstSeqNum;

    private final Queue queue;
    private final AtomicBoolean closed;

    public Batch(SequencedList<byte[]> serialized, Queue q) {
        this(
            serialized.getElements(),
            serialized.getSeqNums().size() == 0 ? -1L : serialized.getSeqNums().get(0), q
        );
    }

    public Batch(List<byte[]> elements, long firstSeqNum, Queue q) {
        this.elements = deserializeElements(elements, q);
        this.firstSeqNum = elements.isEmpty() ? -1L : firstSeqNum;
        this.queue = q;
        this.closed = new AtomicBoolean(false);
    }

    // close acks the batch ackable events
    @Override
    public void close() throws IOException {
        if (closed.getAndSet(true) == false) {
            if (firstSeqNum >= 0L) {
                this.queue.ack(firstSeqNum, elements.size());
            }
        } else {
            // TODO: how should we handle double-closing?
            throw new IOException("double closing batch");
        }
    }

    public int size() {
        return elements.size();
    }

    public List<? extends Queueable> getElements() {
        return elements;
    }

    public Queue getQueue() {
        return queue;
    }

    /**
     *
     * @param serialized Collection of serialized elements
     * @param q {@link Queue} instance
     * @return Collection of deserialized {@link Queueable} elements
     */
    private static List<Queueable> deserializeElements(List<byte[]> serialized, Queue q) {
        final List<Queueable> deserialized = new ArrayList<>(serialized.size());
        for (final byte[] element : serialized) {
            deserialized.add(q.deserialize(element));
        }
        return deserialized;
    }
}
