package org.logstash.ackedqueue;

import java.io.Closeable;

public interface QueueState extends Closeable {
    long getHeadPageIndex();

    void setHeadPageIndex(long index);

    int getHeadPageOffset();

    void setHeadPageOffset(int offset);

    long getUnackedTailPageIndex();

    void setUnackedTailPageIndex(long index);

    long getUnusedTailPageIndex();

    void setUnusedTailPageIndex(long index);

    int getPageSize();

    void setPageSize(int size);
}
