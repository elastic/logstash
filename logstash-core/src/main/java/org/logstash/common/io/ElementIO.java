package org.logstash.common.io;

import org.logstash.ackedqueue.Queueable;

import java.io.IOException;
import java.util.List;

public interface ElementIO {

    // for now ElementIO concrete objects should always be create through open() or create()
    // TODO: refactor interface + concrete class runtime wiring

    // open an existing data container and reconstruct internal state if required
    ElementIO open(int capacity, String path, long minSeqNum, int elementCount) throws IOException;

    // create a new empty data file
    ElementIO create(int capacity, String path) throws IOException;

    // verify if the data container has space for the given number of bytes
    boolean hasSpace(int bytes);

    // write the given bytes to the data container
    void write(byte[] bytes, Queueable element);

    // read up to limit number of items starting at give seqNum
    List<ReadElementValue> read(long seqNum, int limit);

    // @return the data container total capacity in bytes
    int getCapacity();

    // signal that this data page is not active and resources can be released
    void deactivate();

    // signal that this data page is active will be read or written to
    void activate();

    // issue the proper data container "fsync" sematic
    void ensurePersisted();
}
