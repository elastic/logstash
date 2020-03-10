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
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.execution.MemoryReadBatch;
import org.logstash.execution.QueueBatch;
import org.logstash.ext.JrubyEventExtLibrary;

import java.io.IOException;
import java.util.Collection;

import static org.logstash.RubyUtil.RUBY;

public final class AckedReadBatch implements QueueBatch {

    private AckedBatch ackedBatch;

    private RubyHash originals;

    private RubyHash generated;

    public static AckedReadBatch create(final JRubyAckedQueueExt queue, final int size,
                                        final long timeout) {
        return new AckedReadBatch(queue, size, timeout);
    }

    private AckedReadBatch(final JRubyAckedQueueExt queue, final int size, final long timeout) {
        AckedBatch batch;
        try {
            batch = queue.readBatch(size, timeout);
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
        if (batch == null) {
            originals = RubyHash.newHash(RUBY);
            ackedBatch = null;
        } else {
            ackedBatch = batch;
            originals = ackedBatch.toRubyHash(RUBY);
        }
        generated = RubyHash.newHash(RUBY);
    }

    @Override
    public void merge(final IRubyObject event) {
        if (!event.isNil() && !originals.containsKey(event)) {
            generated.put(event, RUBY.getTrue());
        }
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    @Override
    public RubyArray to_a() {
        final RubyArray result = RUBY.newArray(filteredSize());
        for (final JrubyEventExtLibrary.RubyEvent event
                : (Collection<JrubyEventExtLibrary.RubyEvent>) originals.keys()) {
            if (!MemoryReadBatch.isCancelled(event)) {
                result.append(event);
            }
        }
        for (final JrubyEventExtLibrary.RubyEvent event
                : (Collection<JrubyEventExtLibrary.RubyEvent>) generated.keys()) {
            if (!MemoryReadBatch.isCancelled(event)) {
                result.append(event);
            }
        }
        return result;
    }

    public void close() throws IOException {
        if (ackedBatch != null) {
            ackedBatch.close();
        }
    }

    @Override
    public int filteredSize() {
        return originals.size() + generated.size();
    }
}
