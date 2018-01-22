package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIOFactory;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIO;
import org.logstash.ackedqueue.io.PageIOFactory;

public class TestSettings {

    public static Settings persistedQueueSettings(int capacity, String folder) {
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity).elementIOFactory(pageIOFactory)
            .checkpointMaxWrites(1).checkpointIOFactory(checkpointIOFactory)
            .elementClass(StringElement.class).build();
    }

    public static Settings persistedQueueSettings(int capacity, long size, String folder) {
        PageIOFactory pageIOFactory = (pageNum, pageSize, path) -> new MmapPageIO(pageNum, pageSize, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity).elementIOFactory(pageIOFactory)
            .queueMaxBytes(size).checkpointMaxWrites(1).checkpointIOFactory(checkpointIOFactory)
            .elementClass(StringElement.class).build();
    }
}
