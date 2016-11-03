package org.logstash.common.io;

import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.SequencedList;

import java.io.Closeable;
import java.io.IOException;
import java.util.List;

public interface PageIO extends Closeable {

    // the concrete class should be constructed with the pageNum, capacity and dirPath attributes

    // open an existing data container and reconstruct internal state if required
    void open(long minSeqNum, int elementCount) throws IOException;

    // create a new empty data file
    void create() throws IOException;

    // verify if the data container has space for the given number of bytes
    boolean hasSpace(int bytes);

    // write the given bytes to the data container
    void write(byte[] bytes, long seqNum) throws IOException;

    // read up to limit number of items starting at give seqNum
    SequencedList<byte[]> read(long seqNum, int limit) throws IOException;

    // @return the data container total capacity in bytes
    int getCapacity();

    // @return the actual persisted byte count (with overhead) for the given data bytes
    int persistedByteCount(int bytes);

    // signal that this data page is not active and resources can be released
    void deactivate() throws IOException;

    // signal that this data page is active will be read or written to
    // should do nothing if page is aready active
    void activate() throws IOException;

    // issue the proper data container "fsync" sematic
    void ensurePersisted();

    // delete/unlink/remove data file
    void purge() throws IOException;
}
