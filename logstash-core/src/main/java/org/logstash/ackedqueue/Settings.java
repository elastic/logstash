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

import java.util.ArrayList;
import java.util.List;

/**
 * Persistent queue settings definition.
 * */
public interface Settings {

    Class<? extends Queueable> getElementClass();

    String getDirPath();

    int getCapacity();

    long getQueueMaxBytes();

    int getMaxUnread();

    int getCheckpointMaxAcks();

    int getCheckpointMaxWrites();

    boolean getCheckpointRetry();

    CompressionCodec.Factory getCompressionCodecFactory();

    /**
     * Validate and return the settings, or throw descriptive {@link QueueRuntimeException}
     * @param settings the settings to validate
     * @return the settings that were provided
     */
    static Settings ensureValid(final Settings settings) {
        final List<String> errors = new ArrayList<>();

        if (settings == null) {
            errors.add("settings cannot be null");
        } else {
            if (settings.getDirPath() == null) {
                errors.add("dirPath cannot be null");
            }
            if (settings.getElementClass() == null) {
                errors.add("elementClass cannot be null");
            }
        }

        if (!errors.isEmpty()) {
            throw new QueueRuntimeException(String.format("Invalid Queue Settings: %s", errors));
        }

        return settings;
    }

    /**
     * Persistent queue Setting's fluent builder definition
     * */
    interface Builder {

        Builder elementClass(Class<? extends Queueable> elementClass);

        Builder capacity(int capacity);

        Builder queueMaxBytes(long size);

        Builder maxUnread(int maxUnread);

        Builder checkpointMaxAcks(int checkpointMaxAcks);

        Builder checkpointMaxWrites(int checkpointMaxWrites);

        Builder checkpointRetry(boolean checkpointRetry);

        Builder compressionCodecFactory(CompressionCodec.Factory compressionCodecFactory);

        Settings build();
    }
}
