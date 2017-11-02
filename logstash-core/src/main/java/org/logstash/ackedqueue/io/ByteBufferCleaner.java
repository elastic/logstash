package org.logstash.ackedqueue.io;

import java.nio.MappedByteBuffer;

/**
 * Function that forces garbage collection of a {@link MappedByteBuffer}.
 */
@FunctionalInterface
public interface ByteBufferCleaner {

    /**
     * Forces garbage collection of given buffer.
     * @param buffer ByteBuffer to GC
     */
    void clean(MappedByteBuffer buffer);
}
