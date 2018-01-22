package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIOFactory;
import org.logstash.ackedqueue.io.PageIOFactory;

public class SettingsImpl implements Settings {
    private String dirForFiles;
    private CheckpointIOFactory checkpointIOFactory;
    private PageIOFactory pageIOFactory;
    private Class<? extends Queueable> elementClass;
    private int capacity;
    private long queueMaxBytes;
    private int maxUnread;
    private int checkpointMaxAcks;
    private int checkpointMaxWrites;

    public static Builder builder(final Settings settings) {
        return new BuilderImpl(settings.getDirPath(),
            settings.getCheckpointIOFactory(),
            settings.getPageIOFactory(), settings.getElementClass(), settings.getCapacity(),
            settings.getQueueMaxBytes(), settings.getMaxUnread(), settings.getCheckpointMaxAcks(),
            settings.getCheckpointMaxWrites()
        );
    }

    public static Builder fileSettingsBuilder(final String dirForFiles) {
        return new BuilderImpl(dirForFiles);
    }

    private SettingsImpl(final String dirForFiles, final CheckpointIOFactory checkpointIOFactory,
        final PageIOFactory pageIOFactory, final Class<? extends Queueable> elementClass,
        final int capacity, final long queueMaxBytes, final int maxUnread,
        final int checkpointMaxAcks, final int checkpointMaxWrites) {
        this.dirForFiles = dirForFiles;
        this.checkpointIOFactory = checkpointIOFactory;
        this.pageIOFactory = pageIOFactory;
        this.elementClass = elementClass;
        this.capacity = capacity;
        this.queueMaxBytes = queueMaxBytes;
        this.maxUnread = maxUnread;
        this.checkpointMaxAcks = checkpointMaxAcks;
        this.checkpointMaxWrites = checkpointMaxWrites;
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
    public CheckpointIOFactory getCheckpointIOFactory() {
        return checkpointIOFactory;
    }

    public PageIOFactory getPageIOFactory() {
        return pageIOFactory;
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
         * Default max number of writes after which we checkpoint.
         */
        private static final int DEFAULT_CHECKPOINT_MAX_ACKS = 1024;

        /**
         * Default number of acknowledgements after which we checkpoint.
         */
        private static final int DEFAULT_CHECKPOINT_MAX_WRITES = 1024;

        private final String dirForFiles;

        private final CheckpointIOFactory checkpointIOFactory;

        private final PageIOFactory pageIOFactory;

        private final Class<? extends Queueable> elementClass;

        private final int capacity;

        private final long queueMaxBytes;

        private final int maxUnread;

        private final int checkpointMaxAcks;

        private final int checkpointMaxWrites;

        private BuilderImpl(final String dirForFiles) {
            this(dirForFiles, null, null, null, DEFAULT_CAPACITY, DEFAULT_MAX_QUEUE_BYTES,
                DEFAULT_MAX_UNREAD, DEFAULT_CHECKPOINT_MAX_ACKS, DEFAULT_CHECKPOINT_MAX_WRITES
            );
        }

        private BuilderImpl(final String dirForFiles, final CheckpointIOFactory checkpointIOFactory,
            final PageIOFactory pageIOFactory, final Class<? extends Queueable> elementClass,
            final int capacity, final long queueMaxBytes, final int maxUnread,
            final int checkpointMaxAcks, final int checkpointMaxWrites) {
            this.dirForFiles = dirForFiles;
            this.checkpointIOFactory = checkpointIOFactory;
            this.pageIOFactory = pageIOFactory;
            this.elementClass = elementClass;
            this.capacity = capacity;
            this.queueMaxBytes = queueMaxBytes;
            this.maxUnread = maxUnread;
            this.checkpointMaxAcks = checkpointMaxAcks;
            this.checkpointMaxWrites = checkpointMaxWrites;
        }

        @Override
        public Builder checkpointIOFactory(final CheckpointIOFactory factory) {
            return new BuilderImpl(
                this.dirForFiles, factory, this.pageIOFactory, this.elementClass, this.capacity,
                this.queueMaxBytes, this.maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder elementIOFactory(final PageIOFactory factory) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, factory, this.elementClass,
                this.capacity,
                this.queueMaxBytes, this.maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder elementClass(final Class<? extends Queueable> elementClass) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, elementClass,
                this.capacity,
                this.queueMaxBytes, this.maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder capacity(final int capacity) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, this.elementClass,
                capacity, this.queueMaxBytes, this.maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder queueMaxBytes(final long size) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, this.elementClass,
                this.capacity, size, this.maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder maxUnread(final int maxUnread) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, this.elementClass,
                this.capacity, this.queueMaxBytes, maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder checkpointMaxAcks(final int checkpointMaxAcks) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, this.elementClass,
                this.capacity, this.queueMaxBytes, this.maxUnread, checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }

        @Override
        public Builder checkpointMaxWrites(final int checkpointMaxWrites) {
            return new BuilderImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, this.elementClass,
                this.capacity, this.queueMaxBytes, this.maxUnread, this.checkpointMaxAcks,
                checkpointMaxWrites
            );
        }

        @Override
        public Settings build() {
            return new SettingsImpl(
                this.dirForFiles, this.checkpointIOFactory, this.pageIOFactory, this.elementClass,
                this.capacity, this.queueMaxBytes, this.maxUnread, this.checkpointMaxAcks,
                this.checkpointMaxWrites
            );
        }
    }
}
