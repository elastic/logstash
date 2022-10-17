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

/**
 * Persistent queue settings implementation.
 * */
public class SettingsImpl implements Settings {
    private String dirForFiles;
    private Class<? extends Queueable> elementClass;
    private int capacity;
    private long queueMaxBytes;
    private int maxUnread;
    private int checkpointMaxAcks;
    private int checkpointMaxWrites;
    private boolean checkpointRetry;

    public static Builder builder(final Settings settings) {
        return new BuilderImpl(settings.getDirPath(), settings.getElementClass(), settings.getCapacity(),
            settings.getQueueMaxBytes(), settings.getMaxUnread(), settings.getCheckpointMaxAcks(),
            settings.getCheckpointMaxWrites(), settings.getCheckpointRetry()
        );
    }

    public static Builder fileSettingsBuilder(final String dirForFiles) {
        return new BuilderImpl(dirForFiles);
    }

    private SettingsImpl(final String dirForFiles, final Class<? extends Queueable> elementClass,
        final int capacity, final long queueMaxBytes, final int maxUnread,
        final int checkpointMaxAcks, final int checkpointMaxWrites, boolean checkpointRetry) {
        this.dirForFiles = dirForFiles;
        this.elementClass = elementClass;
        this.capacity = capacity;
        this.queueMaxBytes = queueMaxBytes;
        this.maxUnread = maxUnread;
        this.checkpointMaxAcks = checkpointMaxAcks;
        this.checkpointMaxWrites = checkpointMaxWrites;
        this.checkpointRetry = checkpointRetry;
    }

    @Override
    public int getCheckpointMaxAcks() {
        return checkpointMaxAcks;
    }

    @Override
    public int getCheckpointMaxWrites() {
        return checkpointMaxWrites;
    }

    @Override
    public Class<? extends Queueable> getElementClass()  {
        return this.elementClass;
    }

    @Override
    public String getDirPath() {
        return dirForFiles;
    }

    @Override
    public long getQueueMaxBytes() {
        return queueMaxBytes;
    }

    @Override
    public int getCapacity() {
        return capacity;
    }

    @Override
    public int getMaxUnread() {
        return this.maxUnread;
    }

    @Override
    public boolean getCheckpointRetry() {
        return this.checkpointRetry;
    }

    /**
     * Default implementation for Setting's Builder
     * */
    private static final class BuilderImpl implements Builder {

        /**
         * The default Queue has a capacity of 0 events, meaning infinite capacity.
         * todo: Remove the ability to set infinite capacity.
         */
        private static final int DEFAULT_CAPACITY = 0;

        /**
         * The default Queue has a capacity of 0 bytes, meaning infinite capacity.
         * todo: Remove the ability to set infinite capacity.
         */
        private static final long DEFAULT_MAX_QUEUE_BYTES = 0L;

        /**
         * The default max unread count 0, meaning infinite.
         * todo: Remove the ability to set infinite capacity.
         */
        private static final int DEFAULT_MAX_UNREAD = 0;

        /**
         * Default max number of acknowledgements after which we checkpoint.
         */
        private static final int DEFAULT_CHECKPOINT_MAX_ACKS = 1024;

        /**
         * Default max number of writes after which we checkpoint.
         */
        private static final int DEFAULT_CHECKPOINT_MAX_WRITES = 1024;

        private final String dirForFiles;

        private final Class<? extends Queueable> elementClass;

        private final int capacity;

        private final long queueMaxBytes;

        private final int maxUnread;

        private final int checkpointMaxAcks;

        private final int checkpointMaxWrites;

        private final boolean checkpointRetry;

        private BuilderImpl(final String dirForFiles) {
            this(dirForFiles, null, DEFAULT_CAPACITY, DEFAULT_MAX_QUEUE_BYTES,
                DEFAULT_MAX_UNREAD, DEFAULT_CHECKPOINT_MAX_ACKS, DEFAULT_CHECKPOINT_MAX_WRITES, false
            );
        }

        private BuilderImpl(final String dirForFiles, final Class<? extends Queueable> elementClass,
            final int capacity, final long queueMaxBytes, final int maxUnread,
            final int checkpointMaxAcks, final int checkpointMaxWrites, final boolean checkpointRetry) {
            this.dirForFiles = dirForFiles;
            this.elementClass = elementClass;
            this.capacity = capacity;
            this.queueMaxBytes = queueMaxBytes;
            this.maxUnread = maxUnread;
            this.checkpointMaxAcks = checkpointMaxAcks;
            this.checkpointMaxWrites = checkpointMaxWrites;
            this.checkpointRetry = checkpointRetry;
        }

        @Override
        public Builder elementClass(final Class<? extends Queueable> elementClass) {
            return new BuilderImpl(
                this.dirForFiles, elementClass, this.capacity, this.queueMaxBytes, this.maxUnread,
                this.checkpointMaxAcks, this.checkpointMaxWrites, this.checkpointRetry
            );
        }

        @Override
        public Builder capacity(final int capacity) {
            return new BuilderImpl(
                this.dirForFiles, this.elementClass, capacity, this.queueMaxBytes, this.maxUnread,
                this.checkpointMaxAcks, this.checkpointMaxWrites, this.checkpointRetry
            );
        }

        @Override
        public Builder queueMaxBytes(final long size) {
            return new BuilderImpl(
                this.dirForFiles, this.elementClass, this.capacity, size, this.maxUnread,
                this.checkpointMaxAcks, this.checkpointMaxWrites, this.checkpointRetry
            );
        }

        @Override
        public Builder maxUnread(final int maxUnread) {
            return new BuilderImpl(
                this.dirForFiles, this.elementClass,
                this.capacity, this.queueMaxBytes, maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites, this.checkpointRetry
            );
        }

        @Override
        public Builder checkpointMaxAcks(final int checkpointMaxAcks) {
            return new BuilderImpl(
                this.dirForFiles, this.elementClass,
                this.capacity, this.queueMaxBytes, this.maxUnread, checkpointMaxAcks,
                this.checkpointMaxWrites, this.checkpointRetry
            );
        }

        @Override
        public Builder checkpointMaxWrites(final int checkpointMaxWrites) {
            return new BuilderImpl(
                this.dirForFiles, this.elementClass, this.capacity, this.queueMaxBytes,
                this.maxUnread, this.checkpointMaxAcks, checkpointMaxWrites, this.checkpointRetry
            );
        }

        @Override
        public Builder checkpointRetry(final boolean checkpointRetry) {
            return new BuilderImpl(
                    this.dirForFiles, this.elementClass, this.capacity, this.queueMaxBytes,
                    this.maxUnread, this.checkpointMaxAcks, checkpointMaxWrites, checkpointRetry
            );
        }

        @Override
        public Settings build() {
            return new SettingsImpl(
                this.dirForFiles, this.elementClass, this.capacity, this.queueMaxBytes,
                this.maxUnread, this.checkpointMaxAcks, this.checkpointMaxWrites, this.checkpointRetry
            );
        }
    }
}
