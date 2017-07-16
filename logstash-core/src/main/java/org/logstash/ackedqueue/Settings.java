package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIOFactory;
import org.logstash.ackedqueue.io.PageIOFactory;

public interface Settings {

    CheckpointIOFactory getCheckpointIOFactory();

    PageIOFactory getPageIOFactory();

    Class<? extends Queueable> getElementClass();

    String getDirPath();

    int getCapacity();

    long getQueueMaxBytes();

    int getMaxUnread();

    int getCheckpointMaxAcks();

    int getCheckpointMaxWrites();
    
    interface Builder {

        Builder checkpointIOFactory(CheckpointIOFactory factory);

        Builder elementIOFactory(PageIOFactory factory);

        Builder elementClass(Class<? extends Queueable> elementClass);

        Builder capacity(int capacity);

        Builder queueMaxBytes(long size);

        Builder maxUnread(int maxUnread);

        Builder checkpointMaxAcks(int checkpointMaxAcks);

        Builder checkpointMaxWrites(int checkpointMaxWrites);
        
        Settings build();

    }
}
