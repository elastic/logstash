package org.logstash.ackedqueue;

import org.logstash.ackedqueue.io.ByteBufferPageIO;

import java.io.IOException;

/**
 * Class containing common methods to help DRY up acked queue tests.
 */
public class QueueTestHelpers {

    /**
     * Returns the minimum capacity required for {@link ByteBufferPageIO}
     * @return int - minimum capacity required
     */
    public static final int BYTE_BUF_PAGEIO_MIN_CAPACITY = ByteBufferPageIO.WRAPPER_SIZE;

    /**
     * Returns the {@link ByteBufferPageIO} capacity required for the supplied element
     * @param element
     * @return int - capacity required for the supplied element
     * @throws IOException Throws if a serialization error occurs
     */
    public static int singleElementCapacityForByteBufferPageIO(final Queueable element) throws IOException {
        return ByteBufferPageIO.WRAPPER_SIZE + element.serialize().length;
    }
}
