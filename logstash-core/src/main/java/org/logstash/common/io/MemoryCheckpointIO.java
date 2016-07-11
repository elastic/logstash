package org.logstash.common.io;

import org.logstash.ackedqueue.Checkpoint;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class MemoryCheckpointIO implements CheckpointIO {

    private static final Map<String, Checkpoint> sources = new HashMap<>();

    private final String dirPath;

    public static void clearSources() {
        sources.clear();
    }

    public MemoryCheckpointIO(String dirPath) {
        this.dirPath = dirPath;
    }

    @Override
    public Checkpoint read(String fileName) throws IOException {
        return this.sources.get(fileName);
    }

    @Override
    public void write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
        this.sources.put(fileName, checkpoint);
    }

    @Override
    public void purge(String fileName) {
        // do nothing
    }
}
