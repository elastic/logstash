package org.logstash.common.io;

/**
 * Listener interface to receive notification when a DLQ segment is completely read and when are removed.
 * */
public interface SegmentListener {
    /**
     * Notifies the listener about the complete consumption of a bunch of segments.
     * */
    void segmentCompleted();

    /**
     * Notifies the listener about the deletion of consumed segments.
     * It reports the number of deleted segments and number of events contained in those segments.
     *
     * @param numberOfSegments the number of deleted segment files.
     *
     * @param numberOfEvents total number of events that were present in the deleted segments.
     * */
    void segmentsDeleted(int numberOfSegments, long numberOfEvents);
}
