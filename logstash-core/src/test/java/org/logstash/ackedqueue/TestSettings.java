package org.logstash.ackedqueue;

import org.logstash.common.io.ByteBufferPageIO;
import org.logstash.common.io.CheckpointIOFactory;
import org.logstash.common.io.MemoryCheckpointIO;
import org.logstash.common.io.PageIOFactory;

public class TestSettings {

    public static Settings getSettings(int capacity) {
        MemoryCheckpointIO.clearSources();
        Settings s = new MemorySettings();
        PageIOFactory ef = (size, path) -> new ByteBufferPageIO(size, path);
        CheckpointIOFactory ckpf = (source) -> new MemoryCheckpointIO(source);
        s.setCapacity(capacity);
        s.setElementIOFactory(ef);
        s.setCheckpointIOFactory(ckpf);
        return s;
    }
}
