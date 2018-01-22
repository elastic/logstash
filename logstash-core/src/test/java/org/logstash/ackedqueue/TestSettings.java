package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.CheckpointIOFactory;
import org.logstash.ackedqueue.io.FileCheckpointIO;
import org.logstash.ackedqueue.io.MemoryCheckpointIO;
import org.logstash.ackedqueue.io.MmapPageIO;
import org.logstash.ackedqueue.io.PageIOFactory;

public class TestSettings {

    public static Settings volatileQueueSettings(int capacity) {
        MemoryCheckpointIO.clearSources();
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        return SettingsImpl.memorySettingsBuilder().capacity(capacity).elementIOFactory(pageIOFactory)
            .checkpointIOFactory(checkpointIOFactory).elementClass(StringElement.class).build();
    }

    public static Settings volatileQueueSettings(int capacity, long size) {
        MemoryCheckpointIO.clearSources();
        PageIOFactory pageIOFactory = (pageNum, pageSize, path) -> new MmapPageIO(pageNum, pageSize, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        return SettingsImpl.memorySettingsBuilder().capacity(capacity).queueMaxBytes(size)
            .elementIOFactory(pageIOFactory).checkpointIOFactory(checkpointIOFactory)
            .elementClass(StringElement.class).build();
    }

    public static Settings persistedQueueSettings(int capacity, String folder) {
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        return SettingsImpl.fileSettingsBuilder(folder).capacity(capacity).elementIOFactory(pageIOFactory)
            .checkpointMaxWrites(1).checkpointIOFactory(checkpointIOFactory)
            .elementClass(StringElement.class).build();
    }
}
