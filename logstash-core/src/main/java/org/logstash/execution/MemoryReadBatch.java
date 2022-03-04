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
import java.util.ArrayList;
import java.util.Collection;

import static org.logstash.RubyUtil.RUBY;

/**
 * In memory queue collection of events implementation
 * */
public final class MemoryReadBatch implements QueueBatch {

    private final Collection<RubyEvent> events;

    public static boolean isCancelled(final RubyEvent event) {
        return event.getEvent().isCancelled();
    }

    public static MemoryReadBatch create(Collection<RubyEvent> events) {
        return new MemoryReadBatch(events);
    }

    public static MemoryReadBatch create() {
        return new MemoryReadBatch(new ArrayList<>());
    }

    private MemoryReadBatch(final Collection<RubyEvent> events) {
        this.events = events;
    }

    @Override
    public RubyArray<RubyEvent> to_a() {
        @SuppressWarnings({"unchecked"}) final RubyArray<RubyEvent> result = RUBY.newArray(events.size());
        for (final RubyEvent e : events) {
            if (!isCancelled(e)) {
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
    public int filteredSize() {
        return events.size();
    }

    @Override
    public void close() {
        // no-op
    }
}
