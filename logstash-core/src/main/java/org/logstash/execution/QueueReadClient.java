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

import co.elastic.logstash.api.TimerMetric;

import java.io.IOException;

/**
 * Defines the methods to interact with queues from the reader perspective
 * */
public interface QueueReadClient {
    QueueBatch readBatch() throws InterruptedException;
    QueueBatch newBatch();
    void startMetrics(QueueBatch batch);
    void addOutputMetrics(int filteredSize);
    void addFilteredMetrics(int filteredSize);
    void closeBatch(QueueBatch batch) throws IOException;

    public <V, E extends Exception> V executeWithTimers(final TimerMetric.ExceptionalSupplier<V,E> supplier) throws E;

    public <E extends Exception> void executeWithTimers(final TimerMetric.ExceptionalRunnable<E> runnable) throws E;

    boolean isEmpty();
}
