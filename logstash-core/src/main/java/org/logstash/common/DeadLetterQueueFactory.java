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


/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.logstash.common;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.common.io.QueueStorageType;

import java.io.IOException;
import java.nio.file.Paths;
import java.time.Duration;
import java.util.concurrent.ConcurrentHashMap;

/**
 * This class manages static collection of {@link DeadLetterQueueWriter} instances that
 * can be created and retrieved by a specific String-valued key.
 */
public class DeadLetterQueueFactory {

    private static final Logger logger = LogManager.getLogger(DeadLetterQueueFactory.class);
    private static final ConcurrentHashMap<String, DeadLetterQueueWriter> REGISTRY = new ConcurrentHashMap<>();
    private static final long MAX_SEGMENT_SIZE_BYTES = 10 * 1024 * 1024;

    /**
     * This class is only meant to be used statically, and therefore
     * the constructor is private.
     */
    private DeadLetterQueueFactory() {
    }

    /**
     * Retrieves an existing {@link DeadLetterQueueWriter} associated with the given id, or
     * opens a new one to be returned. It is the retrievers responsibility to close these newly
     * created writers.
     *
     * @param id The identifier context for this dlq manager
     * @param dlqPath The path to use for the queue's backing data directory. contains sub-directories
     *                for each id
     * @param maxQueueSize Maximum size of the dead letter queue (in bytes). No entries will be written
     *                     that would make the size of this dlq greater than this value
     * @param flushInterval Maximum duration between flushes of dead letter queue files if no data is sent.
     * @param storageType overwriting type in case of queue full: drop_older or drop_newer.
     * @return write manager for the specific id's dead-letter-queue context
     */
    public static DeadLetterQueueWriter getWriter(String id, String dlqPath, long maxQueueSize, Duration flushInterval, QueueStorageType storageType) {
        return REGISTRY.computeIfAbsent(id, key -> newWriter(key, dlqPath, maxQueueSize, flushInterval, storageType));
    }

    /**
     * Like {@link #getWriter(String, String, long, Duration, QueueStorageType)} but also setting the age duration
     * of the segments.
     *
     * @param id The identifier context for this dlq manager
     * @param dlqPath The path to use for the queue's backing data directory. contains sub-directories
     *                for each id
     * @param maxQueueSize Maximum size of the dead letter queue (in bytes). No entries will be written
     *                     that would make the size of this dlq greater than this value
     * @param flushInterval Maximum duration between flushes of dead letter queue files if no data is sent.
     * @param storageType overwriting type in case of queue full: drop_older or drop_newer.
     * @param age the period that DLQ events should be considered as valid, before automatic removal.
     * @return write manager for the specific id's dead-letter-queue context
     * */
    public static DeadLetterQueueWriter getWriter(String id, String dlqPath, long maxQueueSize, Duration flushInterval, QueueStorageType storageType, Duration age) {
        return REGISTRY.computeIfAbsent(id, key -> newWriter(key, dlqPath, maxQueueSize, flushInterval, storageType, age));
    }

    public static DeadLetterQueueWriter release(String id) {
        return REGISTRY.remove(id);
    }

    private static DeadLetterQueueWriter newWriter(final String id, final String dlqPath, final long maxQueueSize,
                                                   final Duration flushInterval, final QueueStorageType storageType) {
        try {
            return DeadLetterQueueWriter
                    .newBuilder(Paths.get(dlqPath, id), MAX_SEGMENT_SIZE_BYTES, maxQueueSize, flushInterval)
                    .storageType(storageType)
                    .build();
        } catch (IOException e) {
            logger.error("unable to create dead letter queue writer", e);
            return null;
        }
    }

    private static DeadLetterQueueWriter newWriter(final String id, final String dlqPath, final long maxQueueSize,
                                                   final Duration flushInterval, final QueueStorageType storageType,
                                                   final Duration age) {
        try {
            return DeadLetterQueueWriter
                    .newBuilder(Paths.get(dlqPath, id), MAX_SEGMENT_SIZE_BYTES, maxQueueSize, flushInterval)
                    .storageType(storageType)
                    .retentionTime(age)
                    .build();
        } catch (IOException e) {
            logger.error("unable to create dead letter queue writer", e);
            return null;
        }
    }
}
