package org.logstash.ackedqueue;

import java.io.IOException;
import org.logstash.ackedqueue.io.AbstractByteBufferPageIO;

/**
 * Class containing common methods to help DRY up acked queue tests.
 */
public class QueueTestHelpers {

    /**
     * Returns the {@link org.logstash.ackedqueue.io.MmapPageIO} capacity required for the supplied element
     * @param element
     * @return int - capacity required for the supplied element
     * @throws IOException Throws if a serialization error occurs
     */
    public static int singleElementCapacityForByteBufferPageIO(final Queueable element) throws IOException {
        return AbstractByteBufferPageIO.WRAPPER_SIZE + element.serialize().length;
    }
}
