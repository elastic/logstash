package org.logstash.ackedqueue;

public interface Settings {

    Class<? extends Queueable> getElementClass();

    String getDirPath();

    int getCapacity();

    long getQueueMaxBytes();

    int getMaxUnread();

    int getCheckpointMaxAcks();

    int getCheckpointMaxWrites();

    interface Builder {

        Builder elementClass(Class<? extends Queueable> elementClass);

        Builder capacity(int capacity);

        Builder queueMaxBytes(long size);

        Builder maxUnread(int maxUnread);

        Builder checkpointMaxAcks(int checkpointMaxAcks);

        Builder checkpointMaxWrites(int checkpointMaxWrites);

        Settings build();

    }
}
