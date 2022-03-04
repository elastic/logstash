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

/**
 * A counter metric that tracks a single counter.
 *
 * You can retrieve an instance of this class using {@link NamespacedMetric#counter(String)}.
 */
public interface CounterMetric {
    /**
     * Increments the counter by 1.
     */
    void increment();

    /**
     * Increments the counter by {@code delta}.
     *
     * @param delta amount to increment the counter by
     */
    void increment(long delta);

    /**
     * Gets the current value of the counter.
     *
     * @return the counter value
     */
    long getValue();

    /**
     * Sets the counter back to 0.
     */
    void reset();
}
