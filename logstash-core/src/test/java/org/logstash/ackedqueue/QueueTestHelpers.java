package org.logstash.ackedqueue;

import java.io.IOException;
import org.logstash.ackedqueue.io.MmapPageIO;

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
    public static int computeCapacityForMmapPageIO(final Queueable element) throws IOException {
        return computeCapacityForMmapPageIO(element, 1);
    }

    /**
     * Returns the {@link org.logstash.ackedqueue.io.MmapPageI} capacity require to hold a multiple elements including all headers and other metadata.
     * @param element
     * @return int - capacity required for the supplied number of elements
     * @throws IOException Throws if a serialization error occurs
     */
    public static int computeCapacityForMmapPageIO(final Queueable element, int count) throws IOException {
        return MmapPageIO.HEADER_SIZE + (count * (MmapPageIO.SEQNUM_SIZE + MmapPageIO.LENGTH_SIZE + element.serialize().length + MmapPageIO.CHECKSUM_SIZE));
    }
}
