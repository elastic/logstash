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


package co.elastic.logstash.api;

import java.util.Collection;
import java.util.Collections;

/**
 * Logstash Java filter interface. Logstash filters may perform a variety of actions on events as they flow
 * through the Logstash event pipeline including:
 *
 * <ul>
 * <li>Mutation -- Fields in events may be added, removed, or changed by a filter. This is the most common scenario
 * for filters that perform various kinds of enrichment on events.</li>
 * <li>Deletion -- Events may be removed from the event pipeline by a filter so that subsequent filters and outputs
 * do not receive them.</li>
 * <li>Creation -- A filter may insert new events into the event pipeline that will be seen only by subsequent
 * filters and outputs.</li>
 * <li>Observation -- Events may pass unchanged by a filter through the event pipeline. This may be useful in
 * scenarios where a filter performs external actions (e.g., updating an external cache) based on the events observed
 * in the event pipeline.</li>
 * </ul>
 */
public interface Filter extends Plugin {

    /**
     * Events from the event pipeline are presented for filtering through this method. If the filter either mutates
     * the events in-place or simply observes them, the incoming collection of events may be returned without
     * modification. If the filter creates new events, those new events must be added to the returned collection.
     * If the filter deletes events, the deleted events must be removed from the returned collection.
     * @param events        Collection of events to be filtered.
     * @param matchListener Filter match listener to be notified for each matching event. See
     * {@link FilterMatchListener} for more details.
     * @return              Collection of filtered events.
     */
    Collection<Event> filter(Collection<Event> events, FilterMatchListener matchListener);

    /**
     * After a pipeline has been shut down, its filters are closed.
     * If your plugin holds additional resources such as database connections,
     * implementing this method will allow you to free up those resources.
     */
    default void close() { return; }

    /**
     * If this filter maintains state between calls to {@link #filter(Collection, FilterMatchListener)}, this
     * method should return events for all state currently held by the filter. This method will never be called
     * by the Logstash execution engine unless {@link #requiresFlush()} returns {@code true} for this filter.
     * @param matchListener Filter match listener to be notified for each matching event. See
     * {@link FilterMatchListener} for more details.
     * @return              Collection of events for all state currently held by the filter.
     */
    default Collection<Event> flush(FilterMatchListener matchListener) {
        return Collections.emptyList();
    }

    /**
     * @return {@code true} if this filter maintains state between calls to
     * {@link #filter(Collection, FilterMatchListener)} and therefore requires a flush upon pipeline
     * shutdown to return the final events from the filter. The default implementation returns {@code false}
     * as is appropriate for stateless filters.
     */
    default boolean requiresFlush() {
        return false;
    }

    /**
     * @return {@code true} if this filter maintains state between calls to
     * {@link #filter(Collection, FilterMatchListener)} and requires periodic calls to flush events from the filter.
     * If {@code true}, {@link #requiresFlush()} must also return {@code true} for this filter. The default
     * implementation returns {@code false} as is appropriate for stateless filters.
     */
    default boolean requiresPeriodicFlush() {
        return false;
    }

}
