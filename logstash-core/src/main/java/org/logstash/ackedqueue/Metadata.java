package org.logstash.ackedqueue;

import java.io.Closeable;

/**
 * Created by colin on 2016-06-24.
 */
public interface Metadata extends Closeable {
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
