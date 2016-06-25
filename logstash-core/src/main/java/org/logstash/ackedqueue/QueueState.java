package org.logstash.ackedqueue;

import java.io.Closeable;

public interface QueueState extends Closeable {
    int getHeadPageIndex();

    void setHeadPageIndex(int index);

    int getHeadPageOffset();

    void setHeadPageOffset(int offset);

    int getUnackedTailPageIndex();

    void setUnackedTailPageIndex(int index);

    int getUnusedTailPageIndex();

    void setUnusedTailPageIndex(int index);

    int getPageSize();

    void setPageSize(int size);
}
