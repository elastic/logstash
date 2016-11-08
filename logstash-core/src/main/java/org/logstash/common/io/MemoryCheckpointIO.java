package org.logstash.common.io;

import org.logstash.ackedqueue.Checkpoint;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class MemoryCheckpointIO implements CheckpointIO {

    private final String HEAD_CHECKPOINT = "checkpoint.head";
    private final String TAIL_CHECKPOINT = "checkpoint.";

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
    public Checkpoint write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
        write(fileName, checkpoint);
        return checkpoint;
    }

    @Override
    public void write(String fileName, Checkpoint checkpoint) throws IOException {
        this.sources.put(fileName, checkpoint);
    }

    @Override
    public void purge(String fileName) {
        this.sources.remove(fileName);
    }

    @Override
    public void purge() {
        this.sources.clear();
    }

    // @return the head page checkpoint file name
    @Override
    public String headFileName() {
        return HEAD_CHECKPOINT;
    }

    // @return the tail page checkpoint file name for given page number
    @Override
    public String tailFileName(int pageNum) {
        return TAIL_CHECKPOINT + pageNum;
    }

}
