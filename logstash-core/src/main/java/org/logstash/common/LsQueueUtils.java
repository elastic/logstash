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


package org.logstash.common;

import java.util.ArrayList;
import java.util.Collection;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import org.logstash.ext.JrubyEventExtLibrary.RubyEvent;

/**
 * Utilities around {@link BlockingQueue}.
 */
public final class LsQueueUtils {

    private LsQueueUtils() {
        //Utility Class
    }

    /**
     * Adds all {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} in the given collection to the given queue
     * in a blocking manner, only returning once all events have been added to the queue.
     * @param queue Queue to add Events to
     * @param events Events to add to Queue
     * @throws InterruptedException On interrupt during blocking queue add
     */
    public static void addAll(
        final BlockingQueue<RubyEvent> queue,
        final Collection<RubyEvent> events)
        throws InterruptedException
    {
        for (final RubyEvent event : events) {
            queue.put(event);
        }
    }

    /**
     * <p>Drains {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} from {@link BlockingQueue} with a timeout.</p>
     * <p>The timeout will be reset as soon as a single {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} was
     * drained from the {@link BlockingQueue}. Draining {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}
     * stops as soon as either the required number of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}s
     * were pulled from the queue or the timeout value has gone by without an event drained.</p>
     * @param queue Blocking Queue to drain {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}s
     * from
     * @param count Number of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}s to drain from
     * {@link BlockingQueue}
     * @param nanos Timeout in Nanoseconds
     * @return Collection of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} drained from
     * {@link BlockingQueue}
     * @throws InterruptedException On Interrupt during {@link BlockingQueue#poll()} or
     * {@link BlockingQueue#drainTo(Collection)}
     */
    public static Collection<RubyEvent> drain(
        final BlockingQueue<RubyEvent> queue,
        final int count,
        final long nanos)
        throws InterruptedException
    {
        int left = count;
        final ArrayList<RubyEvent> collection = new ArrayList<>(4 * count / 3 + 1);
        do {
            final int drained = drain(queue, collection, left, nanos);
            if (drained == 0) {
                break;
            }
            left -= drained;
        } while (left > 0);
        return collection;
    }

    /**
     * Tries to drain a given number of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} from
     * {@link BlockingQueue} with a timeout.
     * @param queue Blocking Queue to drain {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}s
     * from
     * @param count Number of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent}s to drain from
     * {@link BlockingQueue}
     * @param nanos Timeout in Nanoseconds
     * @return Collection of {@link org.logstash.ext.JrubyEventExtLibrary.RubyEvent} drained from
     * {@link BlockingQueue}
     * @throws InterruptedException On Interrupt during {@link BlockingQueue#poll()} or
     * {@link BlockingQueue#drainTo(Collection)}
     */
    private static int drain(
        final BlockingQueue<RubyEvent> queue,
        final Collection<RubyEvent> collection,
        final int count,
        final long nanos)
        throws InterruptedException
    {
        int added = 0;
        do {
            added += queue.drainTo(collection, count - added);
            if (added < count) {
                final RubyEvent event = queue.poll(nanos, TimeUnit.NANOSECONDS);
                if (event == null) {
                    break;
                }
                collection.add(event);
                added++;
            }
        } while (added < count);
        return added;
    }

}
