package org.logstash.ackedqueue;

import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.PageIOFactory;

public interface Settings {
    Settings setCheckpointIOFactory(CheckpointIOFactory factory);

    Settings setElementIOFactory(PageIOFactory factory);

    Settings setElementClass(Class elementClass);

    Settings setCapacity(int capacity);

    Settings setQueueMaxBytes(long size);

    Settings setMaxUnread(int maxUnread);

    Settings setCheckpointMaxAcks(int checkpointMaxAcks);

    Settings setCheckpointMaxWrites(int checkpointMaxWrites);

    Settings setCheckpointMaxInterval(int checkpointMaxInterval);

    CheckpointIOFactory getCheckpointIOFactory();

    PageIOFactory getPageIOFactory();

    Class getElementClass();

    String getDirPath();

    int getCapacity();

    long getQueueMaxBytes();

    int getMaxUnread();

    int getCheckpointMaxAcks();

    int getCheckpointMaxWrites();

    int getCheckpointMaxInterval();
}
