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
    private final String dirForFiles;
    private final Class<? extends Queueable> elementClass;
    private final int capacity;
    private final long queueMaxBytes;
    private final int maxUnread;
    private final int checkpointMaxAcks;
    private final int checkpointMaxWrites;
    private final boolean checkpointRetry;
    private final CompressionCodec compressionCodec;

    public static Builder builder(final Settings settings) {
        return new BuilderImpl(settings);
    }

    public static Builder fileSettingsBuilder(final String dirForFiles) {
        return new BuilderImpl(dirForFiles);
    }

    private SettingsImpl(final BuilderImpl builder) {
        this.dirForFiles = builder.dirForFiles;
        this.elementClass = builder.elementClass;
        this.capacity = builder.capacity;
        this.queueMaxBytes = builder.queueMaxBytes;
        this.maxUnread = builder.maxUnread;
        this.checkpointMaxAcks = builder.checkpointMaxAcks;
        this.checkpointMaxWrites = builder.checkpointMaxWrites;
        this.checkpointRetry = builder.checkpointRetry;
        this.compressionCodec = builder.compressionCodec;
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

    @Override
    public CompressionCodec getCompressionCodec() {
        return this.compressionCodec;
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

        private Class<? extends Queueable> elementClass;

        private int capacity;

        private long queueMaxBytes;

        private int maxUnread;

        private int checkpointMaxAcks;

        private int checkpointMaxWrites;

        private boolean checkpointRetry;

        private CompressionCodec compressionCodec;

        private BuilderImpl(final String dirForFiles) {
            this.dirForFiles = dirForFiles;
            this.elementClass = null;
            this.capacity = DEFAULT_CAPACITY;
            this.queueMaxBytes = DEFAULT_MAX_QUEUE_BYTES;
            this.maxUnread = DEFAULT_MAX_UNREAD;
            this.checkpointMaxAcks = DEFAULT_CHECKPOINT_MAX_ACKS;
            this.checkpointMaxWrites = DEFAULT_CHECKPOINT_MAX_WRITES;
            this.compressionCodec = CompressionCodec.NOOP;
            this.checkpointRetry = false;
        }

        private BuilderImpl(final Settings settings) {
            this.dirForFiles = settings.getDirPath();
            this.elementClass = settings.getElementClass();
            this.capacity = settings.getCapacity();
            this.queueMaxBytes = settings.getQueueMaxBytes();
            this.maxUnread = settings.getMaxUnread();
            this.checkpointMaxAcks = settings.getCheckpointMaxAcks();
            this.checkpointMaxWrites = settings.getCheckpointMaxWrites();
            this.checkpointRetry = settings.getCheckpointRetry();
            this.compressionCodec = settings.getCompressionCodec();
        }

        @Override
        public Builder elementClass(final Class<? extends Queueable> elementClass) {
            this.elementClass = elementClass;
            return this;
        }

        @Override
        public Builder capacity(final int capacity) {
            this.capacity = capacity;
            return this;
        }

        @Override
        public Builder queueMaxBytes(final long size) {
            this.queueMaxBytes = size;
            return this;
        }

        @Override
        public Builder maxUnread(final int maxUnread) {
            this.maxUnread = maxUnread;
            return this;
        }

        @Override
        public Builder checkpointMaxAcks(final int checkpointMaxAcks) {
            this.checkpointMaxAcks = checkpointMaxAcks;
            return this;
        }

        @Override
        public Builder checkpointMaxWrites(final int checkpointMaxWrites) {
            this.checkpointMaxWrites = checkpointMaxWrites;
            return this;
        }

        @Override
        public Builder checkpointRetry(final boolean checkpointRetry) {
            this.checkpointRetry = checkpointRetry;
            return this;
        }

        @Override
        public Builder compressionCodec(CompressionCodec compressionCodec) {
            this.compressionCodec = compressionCodec;
            return this;
        }

        @Override
        public Settings build() {
            return Settings.ensureValid(new SettingsImpl(this));
        }
    }
}
