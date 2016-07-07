package org.logstash.common.io;

import java.io.IOException;

public interface CheckpointIO {
    void write(int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException;
    int getPageNum();
    long getFirstUnackedSeqNum();
    long getMinSeqNum();
    int getElementCount();
    int getFirstUnackedPageNum();
    void read() throws IOException;
}
