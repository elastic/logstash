package org.logstash.common.io;

/**
 * Callback interface to receive notification when a DLQ segment is completely read and is going to be removed.
 * */
@FunctionalInterface
public interface SegmentListener {
    void segmentCompleted();
}
