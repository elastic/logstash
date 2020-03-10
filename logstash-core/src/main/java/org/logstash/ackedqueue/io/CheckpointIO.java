package org.logstash.ackedqueue.io;

import org.logstash.ackedqueue.Checkpoint;
import java.io.IOException;

public interface CheckpointIO {

    // @return Checkpoint the written checkpoint object
    Checkpoint write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException;

    void write(String fileName, Checkpoint checkpoint) throws IOException;

    Checkpoint read(String fileName) throws IOException;

    void purge(String fileName) throws IOException;

    // @return the head page checkpoint file name
    String headFileName();

    // @return the tail page checkpoint file name for given page number
    String tailFileName(int pageNum);
}
