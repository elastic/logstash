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
import java.util.Collection;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;

import static org.logstash.RubyUtil.RUBY;

public final class AckedReadBatch implements QueueBatch {

    private AckedBatch ackedBatch;

    private Set<RubyEvent> events;

    public static AckedReadBatch create(
        final JRubyAckedQueueExt queue,
        final int size,
        final long timeout)
    {
        return new AckedReadBatch(queue, size, timeout);
    }

    private AckedReadBatch(
        final JRubyAckedQueueExt queue,
        final int size,
        final long timeout)
    {
        AckedBatch batch;
        try {
            batch = queue.readBatch(size, timeout);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
        events = (batch == null) ? new LinkedHashSet<>() : batch.toSet();
        ackedBatch = batch;
    }

    @Override
    public void merge(final RubyEvent event) {
        events.add(event);
    }

    @Override
    public Collection<RubyEvent> collection() {
        // This only returns the originals and does not filter cancelled one
        // because it is  only used in the WorkerLoop where only originals
        // non-cancelled exists. We should revisit this AckedReadBatch
        // implementation and get rid of this dual original/generated idea.
        // The MemoryReadBatch does not use such a strategy.
        return events;
    }

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
