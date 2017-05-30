package org.logstash.ackedqueue.io;

import org.logstash.ackedqueue.Checkpoint;

import java.io.IOException;
import java.nio.file.NoSuchFileException;
import java.util.HashMap;
import java.util.Map;

public class MemoryCheckpointIO implements CheckpointIO {

    private static final String HEAD_CHECKPOINT = "checkpoint.head";
    private static final String TAIL_CHECKPOINT = "checkpoint.";

    private static final Map<String, Map<String, Checkpoint>> sources = new HashMap<>();

    private final String dirPath;

    public static void clearSources() {
        sources.clear();
    }

    public MemoryCheckpointIO(String dirPath) {
        this.dirPath = dirPath;
    }

    @Override
    public Checkpoint read(String fileName) throws IOException {

        Checkpoint cp = null;
        Map<String, Checkpoint> ns = this.sources.get(dirPath);
        if (ns != null) {
           cp = ns.get(fileName);
        }
        if (cp == null) { throw new NoSuchFileException("no memory checkpoint for dirPath: " + this.dirPath + ", fileName: " + fileName); }
        return cp;
    }

    @Override
    public Checkpoint write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException {
        Checkpoint checkpoint = new Checkpoint(pageNum, firstUnackedPageNum, firstUnackedSeqNum, minSeqNum, elementCount);
        write(fileName, checkpoint);
        return checkpoint;
    }

    @Override
    public void write(String fileName, Checkpoint checkpoint) throws IOException {
        Map<String, Checkpoint> ns = this.sources.get(dirPath);
        if (ns == null) {
            ns = new HashMap<>();
            this.sources.put(this.dirPath, ns);
        }
        ns.put(fileName, checkpoint);
    }

    @Override
    public void purge(String fileName) {
        Map<String, Checkpoint> ns = this.sources.get(dirPath);
        if (ns != null) {
           ns.remove(fileName);
        }
    }

    @Override
    public void purge() {
        this.sources.remove(this.dirPath);
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
