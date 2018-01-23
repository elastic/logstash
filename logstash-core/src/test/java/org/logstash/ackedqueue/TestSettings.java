package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIOFactory;
import org.logstash.ackedqueue.io.FileCheckpointIO;

public class TestSettings {

    public static Settings persistedQueueSettings(int capacity, String folder) {
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity)
            .checkpointMaxWrites(1).checkpointIOFactory(checkpointIOFactory)
            .elementClass(StringElement.class).build();
    }

    public static Settings persistedQueueSettings(int capacity, long size, String folder) {
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity)
            .queueMaxBytes(size).checkpointMaxWrites(1).checkpointIOFactory(checkpointIOFactory)
            .elementClass(StringElement.class).build();
    }
}
