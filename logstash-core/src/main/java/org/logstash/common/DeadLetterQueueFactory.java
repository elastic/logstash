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

import java.io.IOException;
import java.nio.file.Paths;
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
     * @return The write manager for the specific id's dead-letter-queue context
     */
    public static DeadLetterQueueWriter getWriter(String id, String dlqPath, long maxQueueSize) {
        return REGISTRY.computeIfAbsent(id, key -> newWriter(key, dlqPath, maxQueueSize));
    }

    public static DeadLetterQueueWriter release(String id) {
        return REGISTRY.remove(id);
    }

    private static DeadLetterQueueWriter newWriter(final String id, final String dlqPath, final long maxQueueSize) {
        try {
            return new DeadLetterQueueWriter(Paths.get(dlqPath, id), MAX_SEGMENT_SIZE_BYTES, maxQueueSize);
        } catch (IOException e) {
            logger.error("unable to create dead letter queue writer", e);
        }
        return null;
    }
}
