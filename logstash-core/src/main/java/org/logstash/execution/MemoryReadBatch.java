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

package org.logstash.execution;

import org.jruby.RubyArray;
import org.logstash.ext.JrubyEventExtLibrary.RubyEvent;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.Set;

import static org.logstash.RubyUtil.RUBY;

public final class MemoryReadBatch implements QueueBatch {

    private final Set<RubyEvent> events;

    public MemoryReadBatch(final Set<RubyEvent> events) {
        this.events = events;
    }

    public static boolean isCancelled(final RubyEvent event) {
        return event.getEvent().isCancelled();
    }

    public static MemoryReadBatch create(Set<RubyEvent> events) {
        return new MemoryReadBatch(events);
    }

    public static MemoryReadBatch create() {
        return create(new LinkedHashSet<>());
    }

    @Override
    public RubyArray<RubyEvent> to_a() {
        @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> result = RUBY.<RubyEvent>newArray(events.size());
        for (final RubyEvent event : events) {
            if (!isCancelled(event)) {
                result.append(event);
            }
        }
        return result;
    }

    @Override
    public Collection<RubyEvent> collection() {
        // This does not filter cancelled events because it is
        // only used in the WorkerLoop where there are no cancelled
        // events yet.
        return events;
    }

    @Override
    public void merge(final RubyEvent event) {
        events.add(event);
    }

    @Override
    public int filteredSize() {
        return events.size();
    }

    @Override
    public void close() {
        // no-op
    }
}
