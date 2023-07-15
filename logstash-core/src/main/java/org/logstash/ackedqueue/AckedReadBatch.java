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

import org.jruby.RubyArray;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.execution.MemoryReadBatch;
import org.logstash.execution.QueueBatch;
import org.logstash.ext.JrubyEventExtLibrary.RubyEvent;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;

import static org.logstash.RubyUtil.RUBY;

/**
 * Persistent queue collection of events implementation
 */
public final class AckedReadBatch implements QueueBatch {

    private final AckedBatch ackedBatch;

    private final Collection<RubyEvent> events;

    public static AckedReadBatch create(
            final JRubyAckedQueueExt queue,
            final int size,
            final long timeout) {
        try {
            final AckedBatch batch = queue.readBatch(size, timeout);
            return (batch == null) ? new AckedReadBatch() : new AckedReadBatch(batch);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    public static AckedReadBatch create() {
        return new AckedReadBatch();
    }

    private AckedReadBatch() {
        ackedBatch = null;
        events = new ArrayList<>();
    }

    private AckedReadBatch(AckedBatch batch) {
        ackedBatch = batch;
        events = batch.events();
    }

    @Override
    public RubyArray<RubyEvent> to_a() {
        @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> result = RUBY.newArray(events.size());
        for (final RubyEvent e : events) {
            if (!MemoryReadBatch.isCancelled(e)) {
                result.append(e);
            }
        }
        return result;
    }

    @Override
    public Collection<RubyEvent> events() {
        // This does not filter cancelled events because it is
        // only used in the WorkerLoop where there are no cancelled
        // events yet.
        return events;
    }

    @Override
    public void close() throws IOException {
        if (ackedBatch != null) {
            ackedBatch.close();
        }
    }

    @Override
    public int filteredSize() {
        return events.size();
    }
}
