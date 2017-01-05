package org.logstash.ackedqueue;

import org.logstash.common.io.ByteBufferPageIO;
import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.FileCheckpointIO;
import org.logstash.common.io.MemoryCheckpointIO;
import org.logstash.common.io.MmapPageIO;
import org.logstash.common.io.PageIOFactory;

public class TestSettings {

    public static Settings volatileQueueSettings(int capacity) {
        MemoryCheckpointIO.clearSources();
        Settings s = new MemorySettings();
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new ByteBufferPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(pageIOFactory);
        s.setCheckpointIOFactory(checkpointIOFactory);
        s.setElementClass(StringElement.class);
        return s;
    }

    public static Settings volatileQueueSettings(int capacity, long size) {
        MemoryCheckpointIO.clearSources();
        Settings s = new MemorySettings();
        PageIOFactory pageIOFactory = (pageNum, pageSize, path) -> new ByteBufferPageIO(pageNum, pageSize, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new MemoryCheckpointIO(source);
        s.setCapacity(capacity);
        s.setQueueMaxBytes(size);
        s.setElementIOFactory(pageIOFactory);
        s.setCheckpointIOFactory(checkpointIOFactory);
        s.setElementClass(StringElement.class);
        return s;
    }

    public static Settings persistedQueueSettings(int capacity, String folder) {
        Settings s = new FileSettings(folder);
        PageIOFactory pageIOFactory = (pageNum, size, path) -> new MmapPageIO(pageNum, size, path);
        CheckpointIOFactory checkpointIOFactory = (source) -> new FileCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(pageIOFactory);
        s.setCheckpointMaxWrites(1);
        s.setCheckpointIOFactory(checkpointIOFactory);
        s.setElementClass(StringElement.class);
        return s;
    }
}
